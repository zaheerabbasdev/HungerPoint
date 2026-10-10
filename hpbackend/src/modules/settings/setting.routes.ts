// ============================================================
// HungerPoint — System Settings Routes
// ============================================================

import { Router } from 'express';
import { SettingController } from './setting.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate);

// System settings (tax rates, delivery fee, business info) are Admin-only.
router.get('/', authorize(UserRole.ADMIN), SettingController.getAll);
router.put('/:key', authorize(UserRole.ADMIN), SettingController.upsert);

export default router;
