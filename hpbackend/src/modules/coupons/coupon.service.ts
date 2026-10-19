// ============================================================
// HungerPoint Backend — Coupon Service
// ============================================================

import { prisma } from '../../config/database';
import { PromotionType, Coupon } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

const NO_USE_STATUSES = ['CANCELLED', 'REJECTED'] as const;

export class CouponService {
  /**
   * Demo vouchers for a development database (called from prisma/seed.ts only).
   * Never run at request time: on a live server only vouchers the Admin creates
   * may exist — an empty table used to be filled with a 50%-off code.
   */
  static async ensureDefaultCoupons() {
    const count = await prisma.coupon.count();
    if (count === 0) {
      await prisma.coupon.createMany({
        data: [
          {
            code: 'WELCOME50',
            description: '50% OFF on your first order up to PKR 500',
            type: PromotionType.PERCENTAGE,
            value: 50,
            minOrderAmount: 500,
            maxDiscount: 500,
            isActive: true,
          },
          {
            code: 'HUNGER20',
            description: 'Flat 20% discount on all gourmet pizzas',
            type: PromotionType.PERCENTAGE,
            value: 20,
            minOrderAmount: 1000,
            maxDiscount: 400,
            isActive: true,
          },
          {
            code: 'PIZZA100',
            description: 'Flat Rs. 100 OFF on any order over Rs. 800',
            type: PromotionType.FIXED_AMOUNT,
            value: 100,
            minOrderAmount: 800,
            maxDiscount: 100,
            isActive: true,
          },
        ],
      });
    }
  }

  /** Vouchers a customer can use right now (started, not expired, not used up). */
  static async getActiveCoupons() {
    const now = new Date();
    const coupons = await prisma.coupon.findMany({
      where: {
        isActive: true,
        AND: [
          { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
          { OR: [{ expiresAt: null }, { expiresAt: { gte: now } }] },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });
    return coupons.filter((c) => c.usageLimit == null || c.usageCount < c.usageLimit);
  }

  static async getAllCoupons() {
    return prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } });
  }

  // Only the voucher's own fields, with numbers checked — the admin form sends
  // strings/blank values, and unknown keys would make Prisma reject the save.
  private static cleanInput(data: any, forUpdate: boolean) {
    const out: Record<string, unknown> = {};
    const num = (v: unknown, field: string, { int = false, min = 0 } = {}) => {
      if (v === '' || v === null) return null;
      const n = Number(v);
      if (!Number.isFinite(n) || n < min || (int && !Number.isInteger(n))) {
        throw new AppError(`${field} must be ${int ? 'a whole number' : 'a number'} of at least ${min}`, 400);
      }
      return n;
    };
    const date = (v: unknown, field: string) => {
      if (v === '' || v === null) return null;
      const d = new Date(v as string);
      if (Number.isNaN(d.getTime())) throw new AppError(`${field} is not a valid date`, 400);
      return d;
    };

    if (data.code !== undefined) {
      const code = String(data.code).toUpperCase().trim();
      if (!/^[A-Z0-9_-]{3,30}$/.test(code)) throw new AppError('Voucher code must be 3–30 letters, digits, - or _', 400);
      out.code = code;
    } else if (!forUpdate) {
      throw new AppError('Voucher code is required', 400);
    }
    if (data.description !== undefined) out.description = data.description ? String(data.description) : null;
    if (data.type !== undefined) {
      if (!Object.values(PromotionType).includes(data.type)) throw new AppError('Choose a voucher type', 400);
      out.type = data.type;
    } else if (!forUpdate) {
      out.type = PromotionType.PERCENTAGE;
    }
    if (data.value !== undefined) {
      const value = num(data.value, 'Value', { min: 0.01 });
      if (value === null) throw new AppError('Value is required', 400);
      out.value = value;
    } else if (!forUpdate) {
      throw new AppError('Value is required', 400);
    }
    const type = (out.type as PromotionType | undefined) ?? data.type;
    if (type === PromotionType.PERCENTAGE && typeof out.value === 'number' && out.value > 100) {
      throw new AppError('A percentage voucher cannot be more than 100%', 400);
    }
    if (data.minOrderAmount !== undefined) out.minOrderAmount = num(data.minOrderAmount, 'Minimum order') ?? 0;
    if (data.maxDiscount !== undefined) out.maxDiscount = num(data.maxDiscount, 'Max discount');
    if (data.usageLimit !== undefined) out.usageLimit = num(data.usageLimit, 'Usage limit', { int: true, min: 1 });
    if (data.perUserLimit !== undefined) out.perUserLimit = num(data.perUserLimit, 'Per-user limit', { int: true }) ?? 1;
    if (data.startsAt !== undefined) out.startsAt = date(data.startsAt, 'Start date');
    if (data.expiresAt !== undefined) out.expiresAt = date(data.expiresAt, 'Expiry date');
    if (data.isActive !== undefined) out.isActive = data.isActive === true || data.isActive === 'true';
    if (out.startsAt && out.expiresAt && (out.expiresAt as Date) <= (out.startsAt as Date)) {
      throw new AppError('Expiry date must be after the start date', 400);
    }
    return out;
  }

  static async createCoupon(data: any) {
    const clean = this.cleanInput(data, false);
    const taken = await prisma.coupon.findUnique({ where: { code: clean.code as string } });
    if (taken) throw new AppError(`A voucher with code ${clean.code} already exists`, 409);
    return prisma.coupon.create({ data: clean as any });
  }

  static async updateCoupon(id: string, data: any) {
    const clean = this.cleanInput(data, true);
    if (clean.code) {
      const taken = await prisma.coupon.findUnique({ where: { code: clean.code as string } });
      if (taken && taken.id !== id) throw new AppError(`A voucher with code ${clean.code} already exists`, 409);
    }
    return prisma.coupon.update({ where: { id }, data: clean as any });
  }

  static async deleteCoupon(id: string) {
    return prisma.coupon.update({ where: { id }, data: { isActive: false } });
  }

  /**
   * Takes one use of a voucher, atomically: the database only increments while
   * the count is under the limit, so two customers can't both get the last use.
   */
  static async claimUse(couponId: string) {
    const changed = await prisma.$executeRaw`
      UPDATE coupons SET usageCount = usageCount + 1
      WHERE id = ${couponId} AND (usageLimit IS NULL OR usageCount < usageLimit)`;
    if (changed === 0) throw new AppError('This voucher has been fully redeemed', 400);
  }

  /** Gives a voucher use back when its order is cancelled/rejected (only once per order). */
  static async releaseForOrder(couponId: string | null | undefined) {
    if (!couponId) return;
    await prisma.coupon.updateMany({
      where: { id: couponId, usageCount: { gt: 0 } },
      data: { usageCount: { decrement: 1 } },
    });
  }

  private static async usesByCustomer(couponId: string, customerId: string) {
    return prisma.order.count({
      where: { customerId, couponId, status: { notIn: [...NO_USE_STATUSES] } },
    });
  }

  /** Preview for the checkout screen. With a signed-in customer it applies the same per-customer limit as checkout. */
  static async validateCoupon(code: string, orderAmount: number = 0, customerId?: string | null) {
    const coupon = await prisma.coupon.findUnique({
      where: { code: code.toUpperCase().trim() },
    });

    const problem = this.checkCoupon(coupon, orderAmount);
    if (problem || !coupon) {
      return { valid: false, message: problem || 'Invalid or expired voucher code', discount: 0 };
    }
    if (customerId && coupon.perUserLimit > 0 && (await this.usesByCustomer(coupon.id, customerId)) >= coupon.perUserLimit) {
      return { valid: false, message: 'You have already used this voucher the maximum number of times', discount: 0 };
    }

    return {
      valid: true,
      message: 'Voucher applied successfully!',
      code: coupon.code,
      discount: this.computeDiscount(coupon, orderAmount),
      coupon,
    };
  }

  // Returns a user-facing reason the coupon can't be used, or null if it can.
  private static checkCoupon(coupon: Coupon | null, orderAmount: number): string | null {
    const now = new Date();
    if (!coupon || !coupon.isActive) return 'Invalid or expired voucher code';
    if (coupon.startsAt && coupon.startsAt > now) return 'This voucher is not active yet';
    if (coupon.expiresAt && coupon.expiresAt < now) return 'This voucher has expired';
    if (coupon.usageLimit != null && coupon.usageCount >= coupon.usageLimit) return 'This voucher has been fully redeemed';
    if (coupon.minOrderAmount && orderAmount < Number(coupon.minOrderAmount)) {
      return `Minimum order amount of PKR ${coupon.minOrderAmount} required for this coupon`;
    }
    return null;
  }

  private static computeDiscount(coupon: Coupon, orderAmount: number): number {
    let discount = 0;
    if (coupon.type === PromotionType.PERCENTAGE) {
      discount = (orderAmount * Number(coupon.value)) / 100;
      if (coupon.maxDiscount && discount > Number(coupon.maxDiscount)) {
        discount = Number(coupon.maxDiscount);
      }
    } else {
      discount = Number(coupon.value);
    }
    return Math.min(Math.round(discount), orderAmount);
  }

  // Authoritative check used when an order is actually placed: same rules as
  // the preview, plus the per-customer limit. Throws so the customer is told
  // why, instead of silently being charged full price.
  static async resolveForOrder(code: string, subtotal: number, customerId?: string | null) {
    const coupon = await prisma.coupon.findUnique({ where: { code: code.toUpperCase().trim() } });
    const problem = this.checkCoupon(coupon, subtotal);
    if (problem || !coupon) throw new AppError(problem || 'Invalid or expired voucher code', 400);

    if (customerId && coupon.perUserLimit > 0) {
      const used = await this.usesByCustomer(coupon.id, customerId);
      if (used >= coupon.perUserLimit) {
        throw new AppError('You have already used this voucher the maximum number of times', 400);
      }
    }

    return { coupon, discount: this.computeDiscount(coupon, subtotal) };
  }
}
