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

export default router;
