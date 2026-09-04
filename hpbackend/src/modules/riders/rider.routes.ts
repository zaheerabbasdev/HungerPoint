// ============================================================
// HungerPoint — Rider Routes
// ============================================================

import { Router } from 'express';
import { RiderController } from './rider.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate);

router.get('/', authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), RiderController.getAll);
router.patch('/status', authorize(UserRole.RIDER), RiderController.updateStatus);
router.post('/location', authorize(UserRole.RIDER), RiderController.updateLocation);
router.post('/assign', authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), RiderController.assignOrder);

export default router;
