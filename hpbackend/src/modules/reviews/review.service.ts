// ============================================================
// HungerPoint — Review Service
// ============================================================

import { prisma } from '../../config/database';

export class ReviewService {
  static async createReview(data: { customerId: string; orderId: string; productId?: string; rating: number; comment?: string }) {
    return prisma.review.create({
      data,
      include: { customer: { include: { user: { select: { name: true } } } } },
    });
  }

  static async getProductReviews(productId: string) {
    return prisma.review.findMany({
      where: { productId, isApproved: true },
      orderBy: { createdAt: 'desc' },
      include: { customer: { include: { user: { select: { name: true } } } } },
    });
  }
}
