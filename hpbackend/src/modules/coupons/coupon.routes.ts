// ============================================================
// HungerPoint Backend — Coupon Routes
// ============================================================

import { Router } from 'express';
import { CouponController } from './coupon.controller';

const router = Router();

router.get('/', CouponController.getActive);
router.post('/validate', CouponController.validate);

export default router;
