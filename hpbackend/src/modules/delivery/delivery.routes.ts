// ============================================================
// HungerPoint — Delivery Routes (rider-facing)
// ============================================================

import { Router } from 'express';
import { DeliveryController } from './delivery.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate, authorize(UserRole.RIDER));

router.get('/me/active', DeliveryController.getActive);
router.get('/me/history', DeliveryController.getHistory);
router.patch('/:id/accept', DeliveryController.accept);
router.patch('/:id/pickup', DeliveryController.pickup);
router.patch('/:id/out-for-delivery', DeliveryController.outForDelivery);
router.patch('/:id/delivered', DeliveryController.delivered);
router.patch('/:id/failed', DeliveryController.failed);

export default router;
