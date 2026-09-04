// ============================================================
// HungerPoint — Review Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReviewService } from './review.service';

export class ReviewController {
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const customerId = (req as any).user?.customerId || (req as any).user?.id;
      const review = await ReviewService.createReview({ ...req.body, customerId });
      res.status(201).json({ success: true, message: 'Review submitted', data: review });
    } catch (error) {
      next(error);
    }
  }

  static async getByProduct(req: Request, res: Response, next: NextFunction) {
    try {
      const reviews = await ReviewService.getProductReviews(req.params.productId as string);
      res.json({ success: true, count: reviews.length, data: reviews });
    } catch (error) {
      next(error);
    }
  }
}
