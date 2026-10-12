// ============================================================
// HungerPoint — Review Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReviewService } from './review.service';
import { CustomerService } from '../customers/customer.service';

// A branch manager moderates only their own branch's reviews (and never "all" by mistake when
// their account has no branch); admins see everything.
const branchScope = (req: Request): string | undefined => {
  const user = (req as any).user;
  return user?.role === 'BRANCH_MANAGER' ? user.branchId || '__no_branch__' : undefined;
};

export class ReviewController {
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const { orderId, productId, rating, comment } = req.body ?? {};
      const review = await ReviewService.createReview({ customerId: customer.id, orderId, productId, rating, comment });
      res.status(201).json({ success: true, message: 'Review submitted', data: review });
    } catch (error) {
      next(error);
    }
  }

  static async getMine(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const reviews = await ReviewService.getMyReviews(customer.id);
      res.json({ success: true, count: reviews.length, data: reviews });
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
      const reviews = await ReviewService.getAllReviews(branchScope(req));
      res.json({ success: true, count: reviews.length, data: reviews });
    } catch (error) {
      next(error);
    }
  }

  static async setApproval(req: Request, res: Response, next: NextFunction) {
    try {
      const { isApproved } = req.body;
      const review = await ReviewService.setApproval(req.params.id as string, Boolean(isApproved), branchScope(req));
      res.json({ success: true, message: 'Review updated', data: review });
    } catch (error) {
      next(error);
    }
  }
}
