// ============================================================
// HungerPoint — Favorites Routes
// ============================================================

import { Router } from 'express';
import { FavoriteController } from './favorite.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/', FavoriteController.getAll);
router.post('/', FavoriteController.add);
router.delete('/:productId', FavoriteController.remove);

export default router;
