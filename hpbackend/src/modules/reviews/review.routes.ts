// ============================================================
// HungerPoint — Review Routes
// ============================================================

import { Router } from 'express';
import { ReviewController } from './review.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

const STAFF = [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER];

router.get('/product/:productId', ReviewController.getByProduct);
router.post('/', authenticate, ReviewController.create);

router.get('/', authenticate, authorize(...STAFF), ReviewController.getAll);
router.patch('/:id/approval', authenticate, authorize(...STAFF), ReviewController.setApproval);

export default router;
