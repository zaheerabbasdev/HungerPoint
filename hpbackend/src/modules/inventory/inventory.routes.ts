// ============================================================
// HungerPoint — Inventory Routes
// ============================================================

import { Router } from 'express';
import { InventoryController } from './inventory.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER));

router.get('/branch/:branchId', InventoryController.getStock);
router.post('/items', InventoryController.addItem);
router.post('/stock', InventoryController.updateStock);

export default router;
