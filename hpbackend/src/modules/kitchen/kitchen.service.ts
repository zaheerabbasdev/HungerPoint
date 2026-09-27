// ============================================================
// HungerPoint — Kitchen Service
// ============================================================

import { prisma } from '../../config/database';
import { OrderStatus } from '@prisma/client';
import { emitToOrder, emitToKitchen, emitToAdmins, SOCKET_EVENTS } from '../../sockets';
import { AppError } from '../../middleware/error.middleware';

export class KitchenService {
  static async getActiveKitchenQueue(branchId?: string) {
    const where: any = {
      status: { in: [OrderStatus.CONFIRMED, OrderStatus.PREPARING] },
    };
    if (branchId) where.branchId = branchId;

    return prisma.order.findMany({
      where,
      orderBy: { createdAt: 'asc' },
      include: {
        items: {
          include: {
            product: { select: { name: true, image: true } },
            variant: { select: { name: true } },
            addons: true,
          },
        },
        customer: { include: { user: { select: { name: true } } } },
      },
    });
  }

  // Loads the order and enforces that the ticket is in an expected state
  // (and, for branch-scoped staff, belongs to their branch).
  private static async getTicket(orderId: string, allowed: OrderStatus[], restrictToBranchId?: string) {
    const order = await prisma.order.findUnique({ where: { id: orderId }, select: { status: true, branchId: true } });
    if (!order || (restrictToBranchId && order.branchId !== restrictToBranchId)) {
      throw new AppError('Order not found', 404);
    }
    if (!allowed.includes(order.status)) {
      throw new AppError(`Order is ${order.status} — this kitchen action isn't allowed right now`, 400);
    }
    return order;
  }

  static async markOrderAsPreparing(orderId: string, estimatedPrepTimeMinutes = 15, restrictToBranchId?: string) {
    await this.getTicket(orderId, [OrderStatus.CONFIRMED, OrderStatus.ACCEPTED], restrictToBranchId);

    const order = await prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.PREPARING,
        acceptedAt: new Date(),
        estimatedPrepTime: estimatedPrepTimeMinutes,
        statusHistory: {
          create: {
            status: OrderStatus.PREPARING,
            notes: `Preparation started (${estimatedPrepTimeMinutes} mins estimated)`,
          },
        },
      },
    });

    emitToOrder(orderId, SOCKET_EVENTS.ORDER_PREPARING, order);
    if (order.branchId) emitToKitchen(order.branchId, 'kitchen.queue_updated', order);
    emitToAdmins(SOCKET_EVENTS.ORDER_PREPARING, order);

    return order;
  }

  static async markOrderAsReady(orderId: string, restrictToBranchId?: string) {
    await this.getTicket(orderId, [OrderStatus.PREPARING], restrictToBranchId);

    const order = await prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.READY,
        readyAt: new Date(),
        preparedAt: new Date(),
        statusHistory: {
          create: {
            status: OrderStatus.READY,
            notes: 'Order is ready for pickup / delivery dispatch',
          },
        },
      },
    });

    emitToOrder(orderId, SOCKET_EVENTS.ORDER_READY, order);
    if (order.branchId) emitToKitchen(order.branchId, 'kitchen.queue_updated', order);
    emitToAdmins(SOCKET_EVENTS.ORDER_READY, order);

    return order;
  }
}
