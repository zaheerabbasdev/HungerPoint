// ============================================================
// HungerPoint — Order Routes
// ============================================================

import { Router } from 'express';
import { OrderController } from './order.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate);

router.post('/', OrderController.create);
router.get('/', OrderController.getAll);
router.get('/:id', OrderController.getById);

// Riders are deliberately excluded: they advance status only through the
// /deliveries lifecycle so Order and Delivery records stay in sync.
router.patch(
  '/:id/status',
  authorize(
    UserRole.SUPER_ADMIN,
    UserRole.ADMIN,
    UserRole.BRANCH_MANAGER,
    UserRole.BRANCH_STAFF,
    UserRole.KITCHEN_STAFF,
    UserRole.WAITER
  ),
  OrderController.updateStatus
);

export default router;
