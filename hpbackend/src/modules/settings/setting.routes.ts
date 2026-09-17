// ============================================================
// HungerPoint — System Settings Routes
// ============================================================

import { Router } from 'express';
import { SettingController } from './setting.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN));

router.get('/', SettingController.getAll);
router.put('/:key', SettingController.upsert);

export default router;
