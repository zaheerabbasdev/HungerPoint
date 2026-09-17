// ============================================================
// HungerPoint — Kitchen Service
// ============================================================

import { prisma } from '../../config/database';
import { OrderStatus } from '@prisma/client';
import { emitToOrder, emitToKitchen, emitToAdmins, SOCKET_EVENTS } from '../../sockets';

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

  static async markOrderAsPreparing(orderId: string, estimatedPrepTimeMinutes = 15) {
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

  static async markOrderAsReady(orderId: string) {
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
