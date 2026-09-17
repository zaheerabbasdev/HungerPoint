// ============================================================
// HungerPoint — Review Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReviewService } from './review.service';
import { CustomerService } from '../customers/customer.service';

export class ReviewController {
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const review = await ReviewService.createReview({ ...req.body, customerId: customer.id });
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

  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const reviews = await ReviewService.getAllReviews();
      res.json({ success: true, count: reviews.length, data: reviews });
    } catch (error) {
      next(error);
    }
  }

  static async setApproval(req: Request, res: Response, next: NextFunction) {
    try {
      const { isApproved } = req.body;
      const review = await ReviewService.setApproval(req.params.id as string, Boolean(isApproved));
      res.json({ success: true, message: 'Review updated', data: review });
    } catch (error) {
      next(error);
    }
  }
}
