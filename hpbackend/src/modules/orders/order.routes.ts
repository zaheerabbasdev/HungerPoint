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

// Status update — Branch Manager, Kitchen Staff, Rider, Waiter, Admin, Super Admin
router.patch(
  '/:id/status',
  authorize(
    UserRole.SUPER_ADMIN,
    UserRole.ADMIN,
    UserRole.BRANCH_MANAGER,
    UserRole.BRANCH_STAFF,
    UserRole.KITCHEN_STAFF,
    UserRole.RIDER,
    UserRole.WAITER
  ),
  OrderController.updateStatus
);

export default router;
