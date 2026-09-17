// ============================================================
// HungerPoint Backend — Coupon Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { CouponService } from './coupon.service';

export class CouponController {
  static async getActive(req: Request, res: Response, next: NextFunction) {
    try {
      const coupons = await CouponService.getActiveCoupons();
      res.json({ success: true, count: coupons.length, data: coupons });
    } catch (error) {
      next(error);
    }
  }

  static async validate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { code, amount } = req.body;
      if (!code) {
        res.status(400).json({ success: false, message: 'Voucher code is required' });
        return;
      }

      const result = await CouponService.validateCoupon(code, Number(amount) || 0);
      res.json({ success: result.valid, ...result });
    } catch (error) {
      next(error);
    }
  }

  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const coupons = await CouponService.getAllCoupons();
      res.json({ success: true, count: coupons.length, data: coupons });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const coupon = await CouponService.createCoupon(req.body);
      res.status(201).json({ success: true, message: 'Coupon created successfully', data: coupon });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const coupon = await CouponService.updateCoupon(req.params.id as string, req.body);
      res.json({ success: true, message: 'Coupon updated successfully', data: coupon });
    } catch (error) {
      next(error);
    }
  }

  static async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await CouponService.deleteCoupon(req.params.id as string);
      res.json({ success: true, message: 'Coupon deactivated successfully' });
    } catch (error) {
      next(error);
    }
  }
}
