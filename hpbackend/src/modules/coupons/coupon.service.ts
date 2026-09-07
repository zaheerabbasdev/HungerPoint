// ============================================================
// HungerPoint Backend — Coupon Service
// ============================================================

import { prisma } from '../../config/database';
import { PromotionType } from '@prisma/client';

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

  static async validateCoupon(code: string, orderAmount: number = 0) {
    await this.ensureDefaultCoupons();

    const coupon = await prisma.coupon.findUnique({
      where: { code: code.toUpperCase().trim() },
    });

    if (!coupon || !coupon.isActive) {
      return { valid: false, message: 'Invalid or expired voucher code', discount: 0 };
    }

    if (coupon.minOrderAmount && orderAmount < Number(coupon.minOrderAmount)) {
      return {
        valid: false,
        message: `Minimum order amount of PKR ${coupon.minOrderAmount} required for this coupon`,
        discount: 0,
      };
    }

    let discount = 0;
    if (coupon.type === PromotionType.PERCENTAGE) {
      discount = (orderAmount * Number(coupon.value)) / 100;
      if (coupon.maxDiscount && discount > Number(coupon.maxDiscount)) {
        discount = Number(coupon.maxDiscount);
      }
    } else {
      discount = Number(coupon.value);
    }

    return {
      valid: true,
      message: 'Voucher applied successfully!',
      code: coupon.code,
      discount: Math.round(discount),
      coupon,
    };
  }
}
