// ============================================================
// HungerPoint Backend — Coupon Service
// ============================================================

import { prisma } from '../../config/database';
import { PromotionType, Coupon } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

export class CouponService {
  /**
   * Seed default vouchers if table is empty
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

  static async getActiveCoupons() {
    await this.ensureDefaultCoupons();
    return prisma.coupon.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  static async getAllCoupons() {
    await this.ensureDefaultCoupons();
    return prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } });
  }

  static async createCoupon(data: {
    code: string;
    description?: string;
    type: PromotionType;
    value: number;
    minOrderAmount?: number;
    maxDiscount?: number;
    usageLimit?: number;
    perUserLimit?: number;
    startsAt?: string | Date;
    expiresAt?: string | Date;
  }) {
    return prisma.coupon.create({
      data: {
        ...data,
        code: data.code.toUpperCase().trim(),
        startsAt: data.startsAt ? new Date(data.startsAt) : undefined,
        expiresAt: data.expiresAt ? new Date(data.expiresAt) : undefined,
      },
    });
  }

  static async updateCoupon(id: string, data: any) {
    const { code, startsAt, expiresAt, ...rest } = data;
    return prisma.coupon.update({
      where: { id },
      data: {
        ...rest,
        ...(code !== undefined ? { code: code.toUpperCase().trim() } : {}),
        ...(startsAt !== undefined ? { startsAt: startsAt ? new Date(startsAt) : null } : {}),
        ...(expiresAt !== undefined ? { expiresAt: expiresAt ? new Date(expiresAt) : null } : {}),
      },
    });
  }

  static async deleteCoupon(id: string) {
    return prisma.coupon.update({ where: { id }, data: { isActive: false } });
  }

  static async validateCoupon(code: string, orderAmount: number = 0) {
    await this.ensureDefaultCoupons();

    const coupon = await prisma.coupon.findUnique({
      where: { code: code.toUpperCase().trim() },
    });

    const problem = this.checkCoupon(coupon, orderAmount);
    if (problem || !coupon) {
      return { valid: false, message: problem || 'Invalid or expired voucher code', discount: 0 };
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
      const used = await prisma.order.count({
        where: { customerId, couponId: coupon.id, status: { notIn: ['CANCELLED', 'REJECTED'] } },
      });
      if (used >= coupon.perUserLimit) {
        throw new AppError('You have already used this voucher the maximum number of times', 400);
      }
    }

    return { coupon, discount: this.computeDiscount(coupon, subtotal) };
  }
}
