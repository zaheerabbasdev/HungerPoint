// ============================================================
// HungerPoint — Kitchen Routes
// ============================================================

import { Router } from 'express';
import { KitchenController } from './kitchen.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

// Kitchen is a fully separate console: only Kitchen Staff accounts may use it.
router.use(authenticate, authorize(UserRole.KITCHEN_STAFF));

router.get('/queue', KitchenController.getQueue);
router.patch('/orders/:id/prepare', KitchenController.startPreparing);
router.patch('/orders/:id/extend', KitchenController.extend);
router.patch('/orders/:id/ready', KitchenController.markReady);

export default router;
