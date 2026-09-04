// ============================================================
// HungerPoint — Branch Routes
// ============================================================

import { Router } from 'express';
import { BranchController } from './branch.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

// Public routes
router.get('/', BranchController.getAll);
router.get('/:id', BranchController.getById);

// Admin-only routes
router.post('/', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), BranchController.create);
router.put('/:id', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), BranchController.update);
router.delete('/:id', authenticate, authorize(UserRole.SUPER_ADMIN), BranchController.remove);

export default router;
