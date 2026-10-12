// ============================================================
// HungerPoint — Review Service
// ============================================================

import { Prisma, OrderStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';

const MAX_COMMENT_LENGTH = 1000;

export class ReviewService {
  static async createReview(data: { customerId: string; orderId?: string; productId?: string; rating: unknown; comment?: unknown }) {
    const rating = Number(data.rating);
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw new AppError('Rating must be a whole number from 1 to 5', 400);
    }
    if (!data.orderId) throw new AppError('Choose the order you are reviewing', 400);
    const comment = typeof data.comment === 'string' ? data.comment.trim().slice(0, MAX_COMMENT_LENGTH) || undefined : undefined;

    const order = await prisma.order.findUnique({
      where: { id: data.orderId },
      include: { items: { select: { productId: true } }, review: { select: { id: true } } },
    });
    if (!order) throw new AppError('Order not found', 404);
    if (order.customerId !== data.customerId) throw new AppError('You can only review your own orders', 403);
    const reviewableStatuses: OrderStatus[] = [OrderStatus.DELIVERED, OrderStatus.COMPLETED];
    if (!reviewableStatuses.includes(order.status)) {
      throw new AppError('Only completed orders can be reviewed', 400);
    }
    if (order.review) throw new AppError('You have already reviewed this order', 409);

    // A review belongs to the order; it is also linked to a product of that order so it can be
    // shown with the item. Use the one the app named if it really is in the order, else the first.
    const productIds = order.items.map((i) => i.productId);
    const productId = data.productId && productIds.includes(data.productId) ? data.productId : productIds[0];

    try {
      return await prisma.review.create({
        data: { customerId: data.customerId, orderId: data.orderId, productId, rating, comment },
        include: { customer: { include: { user: { select: { name: true } } } } },
      });
    } catch (err) {
      // Two taps at once: the unique orderId guard catches the second one.
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        throw new AppError('You have already reviewed this order', 409);
      }
      throw err;
    }
  }

  static async getProductReviews(productId: string) {
    return prisma.review.findMany({
      where: { productId, isApproved: true },
      orderBy: { createdAt: 'desc' },
      include: { customer: { include: { user: { select: { name: true } } } } },
    });
  }

  /** The signed-in customer's own reviews, newest first. */
  static async getMyReviews(customerId: string) {
    return prisma.review.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
      include: {
        order: { select: { orderNumber: true } },
        product: { select: { name: true } },
      },
    });
  }

  /** All reviews for moderation. A branch manager passes their branchId to see only their branch. */
  static async getAllReviews(branchId?: string) {
    return prisma.review.findMany({
      where: branchId ? { order: { branchId } } : {},
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { include: { user: { select: { name: true, phone: true } } } },
        product: { select: { name: true, image: true } },
        order: { select: { orderNumber: true, branchId: true } },
      },
    });
  }

  static async setApproval(id: string, isApproved: boolean, branchId?: string) {
    const review = await prisma.review.findUnique({ where: { id }, include: { order: { select: { branchId: true } } } });
    if (!review || (branchId && review.order.branchId !== branchId)) throw new AppError('Review not found', 404);
    return prisma.review.update({ where: { id }, data: { isApproved } });
  }
}
