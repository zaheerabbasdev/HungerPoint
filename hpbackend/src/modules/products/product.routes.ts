// ============================================================
// HungerPoint — Product Routes
// ============================================================

import { Router } from 'express';
import { ProductController } from './product.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

// Addons routes
router.get('/addons/all', ProductController.getAllAddons);
router.post('/addons', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), ProductController.createAddon);
router.delete('/addons/:id', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), ProductController.deleteAddon);

// Public routes
router.get('/', ProductController.getAll);
router.get('/:id', ProductController.getById);

// Admin-only routes
router.post('/', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), ProductController.create);
router.put('/:id', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), ProductController.update);
router.delete('/:id', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), ProductController.remove);

// Product Variant routes
router.post('/:id/variants', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), ProductController.addVariant);
router.put('/variants/:variantId', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER), ProductController.updateVariant);
router.delete('/variants/:variantId', authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), ProductController.deleteVariant);

export default router;
