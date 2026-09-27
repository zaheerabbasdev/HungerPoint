// ============================================================
// HungerPoint — System Settings Routes
// ============================================================

import { Router } from 'express';
import { SettingController } from './setting.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate);

// Admins can view system settings, but only a Super Admin may change them —
// this config covers business-wide config like payment gateway keys and tax
// rates, which should have a single point of accountability.
router.get('/', authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN), SettingController.getAll);
router.put('/:key', authorize(UserRole.SUPER_ADMIN), SettingController.upsert);

export default router;
