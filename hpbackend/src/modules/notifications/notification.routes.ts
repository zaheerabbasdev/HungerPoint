// ============================================================
// HungerPoint Backend — Notification Routes
// ============================================================

import { Router } from 'express';
import { NotificationController } from './notification.controller';

const router = Router();

router.get('/', NotificationController.getAll);
router.patch('/:id/read', NotificationController.markRead);

export default router;
