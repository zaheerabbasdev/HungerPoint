// ============================================================
// HungerPoint Backend — Notification Routes
// ============================================================

import { Router } from 'express';
import { NotificationController } from './notification.controller';
import { authenticate, optionalAuth } from '../../middleware/auth.middleware';

const router = Router();

// Guests still see broadcast notifications; signed-in users also get their own.
router.get('/', optionalAuth, NotificationController.getAll);
router.patch('/read-all', authenticate, NotificationController.markAllRead);
router.patch('/:id/read', authenticate, NotificationController.markRead);

export default router;
