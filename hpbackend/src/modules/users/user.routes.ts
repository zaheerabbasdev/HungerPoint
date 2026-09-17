// ============================================================
// HungerPoint — User (Staff Account) Routes
// ============================================================

import { Router } from 'express';
import { UserController } from './user.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticate, authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN));

router.get('/', UserController.getAll);
router.post('/', UserController.create);
router.put('/:id', UserController.update);

export default router;
