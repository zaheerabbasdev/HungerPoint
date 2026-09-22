// ============================================================
// HungerPoint — Table Reservation Routes
// ============================================================

import { Router } from 'express';
import { ReservationController } from './reservation.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate);

const STAFF = authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER, UserRole.BRANCH_STAFF, UserRole.WAITER);

router.get('/', STAFF, ReservationController.getAll);
router.post('/', STAFF, ReservationController.create);
router.patch('/:id/seat', STAFF, ReservationController.seat);
router.patch('/:id/cancel', STAFF, ReservationController.cancel);

export default router;
