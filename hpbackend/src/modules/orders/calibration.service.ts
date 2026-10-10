// ============================================================
// HungerPoint — Self-correcting delivery estimates
//
// Map services give the road time; the rest of the accuracy comes from how this branch really
// performs. For each branch this compares past estimates with what actually happened and returns
// two correction factors:
//   ride  = actual ride time / map ride time        (how fast this branch's riders really are)
//   prep  = actual cooking time / minutes the cook entered   (does the kitchen run over?)
//
// It uses the median (one bad order cannot skew it), ignores absurd outliers, needs a minimum
// number of finished orders before changing anything, and never moves an estimate by more than 2x.
// ============================================================

import { OrderStatus, OrderType } from '@prisma/client';
import { prisma } from '../../config/database';

const WINDOW_DAYS = 30;
const SAMPLE_LIMIT = 30;
const CACHE_TTL_MS = 10 * 60_000;
const MIN_FACTOR = 0.8;
const MAX_FACTOR = 2.0;
// A single ratio outside this range is a data accident (forgotten tap, test order), not signal.
const MIN_RATIO = 0.3;
const MAX_RATIO = 4;

export interface CalibrationFactors {
  ride: number;
  prep: number;
  rideSamples: number;
  prepSamples: number;
}

const NEUTRAL: CalibrationFactors = { ride: 1, prep: 1, rideSamples: 0, prepSamples: 0 };
const cache = new Map<string, { factors: CalibrationFactors; at: number }>();

const minSamples = (): number => Math.max(3, Number(process.env.ETA_CALIBRATION_MIN_SAMPLES) || 10);
const enabled = (): boolean => (process.env.ETA_CALIBRATION || 'on').toLowerCase() !== 'off';

const median = (values: number[]): number => {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
};

const factorFrom = (ratios: number[]): number | null => {
  const usable = ratios.filter((r) => Number.isFinite(r) && r >= MIN_RATIO && r <= MAX_RATIO);
  if (usable.length < minSamples()) return null;
  return Math.min(MAX_FACTOR, Math.max(MIN_FACTOR, median(usable)));
};

export class CalibrationService {
  static async getFactors(branchId?: string | null): Promise<CalibrationFactors> {
    if (!branchId || !enabled()) return NEUTRAL;

    const hit = cache.get(branchId);
    if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.factors;

    try {
      const since = new Date(Date.now() - WINDOW_DAYS * 24 * 60 * 60_000);
      const finished = [OrderStatus.DELIVERED, OrderStatus.COMPLETED];

      const [rides, preps] = await Promise.all([
        prisma.order.findMany({
          where: {
            branchId, type: OrderType.DELIVERY, status: { in: finished }, deliveredAt: { gte: since },
            mapRideMinutes: { gt: 0 }, pickedUpAt: { not: null },
          },
          orderBy: { deliveredAt: 'desc' },
          take: SAMPLE_LIMIT,
          select: { mapRideMinutes: true, pickedUpAt: true, deliveredAt: true },
        }),
        prisma.order.findMany({
          where: {
            branchId, status: { in: finished }, createdAt: { gte: since },
            prepMinutesEntered: { gt: 0 }, acceptedAt: { not: null }, readyAt: { not: null },
          },
          orderBy: { createdAt: 'desc' },
          take: SAMPLE_LIMIT,
          select: { prepMinutesEntered: true, acceptedAt: true, readyAt: true },
        }),
      ]);

      const rideRatios = rides.map((o) => {
        const actual = (o.deliveredAt!.getTime() - o.pickedUpAt!.getTime()) / 60_000;
        return actual / o.mapRideMinutes!;
      });
      const prepRatios = preps.map((o) => {
        const actual = (o.readyAt!.getTime() - o.acceptedAt!.getTime()) / 60_000;
        return actual / o.prepMinutesEntered!;
      });

      const ride = factorFrom(rideRatios);
      const prep = factorFrom(prepRatios);
      const factors: CalibrationFactors = {
        ride: ride ?? 1,
        prep: prep ?? 1,
        rideSamples: rideRatios.length,
        prepSamples: prepRatios.length,
      };

      const before = cache.get(branchId)?.factors;
      if (!before || before.ride !== factors.ride || before.prep !== factors.prep) {
        console.log(
          `[eta] branch ${branchId} calibration: ride x${factors.ride.toFixed(2)} (${factors.rideSamples} orders), ` +
          `prep x${factors.prep.toFixed(2)} (${factors.prepSamples} orders)`,
        );
      }
      cache.set(branchId, { factors, at: Date.now() });
      return factors;
    } catch (err) {
      console.error('ETA calibration failed, using uncorrected estimates:', err);
      return NEUTRAL;
    }
  }

  /** Map ride minutes corrected for how this branch's riders really perform. 0 stays 0. */
  static applyRide(rawMinutes: number, factors: CalibrationFactors): number {
    if (rawMinutes <= 0) return 0;
    return Math.max(1, Math.round(rawMinutes * factors.ride));
  }

  /** Cook's prep minutes corrected for how this branch's kitchen really performs. */
  static applyPrep(enteredMinutes: number, factors: CalibrationFactors): number {
    return Math.max(1, Math.round(enteredMinutes * factors.prep));
  }

  /** For tests / after bulk data changes. */
  static clearCache(): void {
    cache.clear();
  }
}
