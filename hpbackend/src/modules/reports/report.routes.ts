// ============================================================
// HungerPoint — Report Routes
// ============================================================

import { Router } from 'express';
import { ReportController } from './report.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER));

router.get('/overview', ReportController.getOverview);
router.get('/orders-by-status', ReportController.getOrdersByStatus);
router.get('/top-products', ReportController.getTopProducts);
router.get('/orders-by-source', ReportController.getOrdersBySource);

export default router;
