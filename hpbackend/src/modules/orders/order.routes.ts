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
    UserRole.ADMIN,
    UserRole.BRANCH_MANAGER,
    UserRole.BRANCH_STAFF,
    UserRole.KITCHEN_STAFF,
    UserRole.WAITER
  ),
  OrderController.updateStatus
);

// Dine-in finish: served ("Mark as done") then payment, which closes the table.
router.patch(
  '/:id/served',
  authorize(UserRole.ADMIN, UserRole.BRANCH_MANAGER, UserRole.BRANCH_STAFF, UserRole.WAITER),
  OrderController.markServed
);
router.patch(
  '/:id/payment',
  authorize(UserRole.ADMIN, UserRole.BRANCH_MANAGER, UserRole.BRANCH_STAFF, UserRole.WAITER),
  OrderController.confirmPayment
);

export default router;
