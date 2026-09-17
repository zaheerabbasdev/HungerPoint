// ============================================================
// HungerPoint Backend — Coupon Routes
// ============================================================

import { Router } from 'express';
import { CouponController } from './coupon.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

const STAFF = [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER];

router.get('/', CouponController.getActive);
router.post('/validate', CouponController.validate);

router.get('/admin', authenticate, authorize(...STAFF), CouponController.getAll);
router.post('/', authenticate, authorize(...STAFF), CouponController.create);
router.put('/:id', authenticate, authorize(...STAFF), CouponController.update);
router.delete('/:id', authenticate, authorize(...STAFF), CouponController.remove);

export default router;
