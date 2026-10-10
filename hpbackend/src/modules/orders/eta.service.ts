// ============================================================
// HungerPoint — Promised-time refresh
// The time shown to the customer (order.promisedAt) first uses an instant estimate. This
// replaces it with the road-based time as soon as the routing service answers, then tells the
// customer's, admin's and branch riders' screens.
// ============================================================

import { OrderStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { RoutingService } from '../../utils/routing';
import { CalibrationService } from './calibration.service';
import { emitToOrder, emitToAdmins, emitToBranchRiders, SOCKET_EVENTS } from '../../sockets';

const ON_THE_WAY: OrderStatus[] = [OrderStatus.PICKED_UP, OrderStatus.OUT_FOR_DELIVERY];
const FINISHED: OrderStatus[] = [
  OrderStatus.DELIVERED, OrderStatus.COMPLETED, OrderStatus.CANCELLED,
  OrderStatus.REJECTED, OrderStatus.REFUNDED, OrderStatus.PAYMENT_FAILED,
];

export class EtaService {
  /**
   * Recomputes ride time by road and the promised time. `from` is the rider's live position when
   * known; otherwise the branch. Safe to fire-and-forget: it never throws.
   */
  static async refresh(orderId: string, from?: { latitude: number; longitude: number }): Promise<void> {
    try {
      const order = await prisma.order.findUnique({
        where: { id: orderId },
        select: {
          status: true, type: true, branchId: true, acceptedAt: true, estimatedPrepTime: true,
          promisedAt: true, estimatedDeliveryTime: true, promisedPrepMinutes: true,
          branch: { select: { latitude: true, longitude: true } },
          address: { select: { latitude: true, longitude: true } },
        },
      });
      if (!order || order.type !== 'DELIVERY' || FINISHED.includes(order.status)) return;

      const raw = await RoutingService.travelMinutes(from ?? order.branch, order.address);
      const factors = await CalibrationService.getFactors(order.branchId);
      const minutes = CalibrationService.applyRide(raw, factors);

      // Food still being made: the customer waits for the rest of the prep, then the ride.
      // Food in the rider's hands: just the ride.
      const now = Date.now();
      let start = now;
      if (!ON_THE_WAY.includes(order.status) && order.acceptedAt && order.estimatedPrepTime) {
        const prep = order.promisedPrepMinutes ?? order.estimatedPrepTime;
        start = Math.max(now, order.acceptedAt.getTime() + prep * 60_000);
      }
      const promisedAt = new Date(start + minutes * 60_000);

      const sameRide = order.estimatedDeliveryTime === minutes;
      const closeEnough = order.promisedAt && Math.abs(promisedAt.getTime() - order.promisedAt.getTime()) < 60_000;
      if (sameRide && closeEnough) return;

      // The full branch -> customer estimate is what the rider-speed learning compares with; a live
      // update from the rider's position is only the remaining part, so it is not stored for learning.
      await prisma.order.update({
        where: { id: orderId },
        data: { promisedAt, estimatedDeliveryTime: minutes, ...(from ? {} : { mapRideMinutes: raw }) },
      });
      const payload = { orderId, promisedAt };
      emitToOrder(orderId, SOCKET_EVENTS.ORDER_ETA_UPDATED, payload);
      emitToAdmins(SOCKET_EVENTS.ORDER_ETA_UPDATED, payload);
      if (order.branchId) emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId, status: order.status });
    } catch (err) {
      console.error('ETA refresh failed:', err);
    }
  }
}
