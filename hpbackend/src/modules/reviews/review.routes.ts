// ============================================================
// HungerPoint — Review Routes
// ============================================================

import { Router } from 'express';
import { ReviewController } from './review.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

router.get('/product/:productId', ReviewController.getByProduct);
router.post('/', authenticate, ReviewController.create);

export default router;
