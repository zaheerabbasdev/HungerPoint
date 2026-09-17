// ============================================================
// HungerPoint — Review Service
// ============================================================

import { prisma } from '../../config/database';
import { OrderStatus } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

export class ReviewService {
  static async createReview(data: { customerId: string; orderId: string; productId?: string; rating: number; comment?: string }) {
    const order = await prisma.order.findUnique({ where: { id: data.orderId } });
    if (!order) throw new AppError('Order not found', 404);
    if (order.customerId !== data.customerId) throw new AppError('You can only review your own orders', 403);
    const reviewableStatuses: OrderStatus[] = [OrderStatus.DELIVERED, OrderStatus.COMPLETED];
    if (!reviewableStatuses.includes(order.status)) {
      throw new AppError('Only completed orders can be reviewed', 400);
    }

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

  static async getAllReviews() {
    return prisma.review.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { include: { user: { select: { name: true, phone: true } } } },
        product: { select: { name: true, image: true } },
        order: { select: { orderNumber: true, branchId: true } },
      },
    });
  }

  static async setApproval(id: string, isApproved: boolean) {
    return prisma.review.update({ where: { id }, data: { isApproved } });
  }
}
