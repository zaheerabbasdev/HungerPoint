// ============================================================
// HungerPoint — Loyalty Routes
// ============================================================

import { Router } from 'express';
import { LoyaltyController } from './loyalty.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate);

const STAFF = [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER];

router.get('/me', LoyaltyController.getMyAccount);

router.get('/', authorize(...STAFF), LoyaltyController.getAll);
router.get('/:customerId', authorize(...STAFF), LoyaltyController.getAccount);
router.post('/adjust', authorize(...STAFF), LoyaltyController.adjust);

export default router;
