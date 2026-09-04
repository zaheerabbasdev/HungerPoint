// ============================================================
// HungerPoint — Category Routes
// ============================================================

import { Router } from 'express';
import { CategoryController } from './category.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

// Public routes
router.get('/', CategoryController.getAll);
router.get('/:id', CategoryController.getById);

// Admin-only routes
router.post('/', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), CategoryController.create);
router.put('/:id', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), CategoryController.update);
router.delete('/:id', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), CategoryController.remove);

export default router;
