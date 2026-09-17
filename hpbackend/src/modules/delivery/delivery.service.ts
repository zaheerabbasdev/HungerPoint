// ============================================================
// HungerPoint — Delivery Service (rider-facing delivery lifecycle)
// ============================================================

import { prisma } from '../../config/database';
import { DeliveryStatus, OrderStatus, RiderStatus } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';
import { OrderService } from '../orders/order.service';

const INCLUDE_FULL_DELIVERY = {
  order: {
    include: {
      items: { include: { product: true, variant: true, addons: true } },
      customer: { include: { user: { select: { name: true, phone: true } } } },
      address: true,
      branch: true,
    },
  },
};

export class DeliveryService {
  /** The rider's current non-terminal delivery, if any. */
  static async getActiveForRider(riderId: string) {
    return prisma.delivery.findFirst({
      where: {
        riderId,
        status: { in: [DeliveryStatus.ASSIGNED, DeliveryStatus.ACCEPTED, DeliveryStatus.PICKED_UP, DeliveryStatus.OUT_FOR_DELIVERY] },
      },
      orderBy: { assignedAt: 'desc' },
      include: INCLUDE_FULL_DELIVERY,
    });
  }

  static async getHistoryForRider(riderId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const where = { riderId, status: { in: [DeliveryStatus.DELIVERED, DeliveryStatus.FAILED] } };

    const [total, deliveries] = await Promise.all([
      prisma.delivery.count({ where }),
      prisma.delivery.findMany({
        where,
        skip,
        take: limit,
        orderBy: { updatedAt: 'desc' },
        include: INCLUDE_FULL_DELIVERY,
      }),
    ]);

    return { total, page, limit, totalPages: Math.ceil(total / limit), deliveries };
  }

  private static async getOwnedDelivery(deliveryId: string, riderId: string) {
    const delivery = await prisma.delivery.findUnique({ where: { id: deliveryId } });
    if (!delivery) throw new AppError('Delivery not found', 404);
    if (delivery.riderId !== riderId) throw new AppError('This delivery is not assigned to you', 403);
    return delivery;
  }

  static async accept(deliveryId: string, riderId: string) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    if (delivery.status !== DeliveryStatus.ASSIGNED) {
      throw new AppError(`Cannot accept a delivery in ${delivery.status} status`, 400);
    }

    const updated = await prisma.delivery.update({
      where: { id: deliveryId },
      data: { status: DeliveryStatus.ACCEPTED, acceptedAt: new Date() },
      include: INCLUDE_FULL_DELIVERY,
    });
    return updated;
  }

  static async markPickedUp(deliveryId: string, riderId: string) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    if (delivery.status !== DeliveryStatus.ACCEPTED) {
      throw new AppError(`Cannot mark picked up from ${delivery.status} status`, 400);
    }

    const updated = await prisma.delivery.update({
      where: { id: deliveryId },
      data: { status: DeliveryStatus.PICKED_UP, pickedUpAt: new Date() },
      include: INCLUDE_FULL_DELIVERY,
    });
    await OrderService.updateOrderStatus(delivery.orderId, OrderStatus.PICKED_UP);
    return updated;
  }

  static async markOutForDelivery(deliveryId: string, riderId: string) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    if (delivery.status !== DeliveryStatus.PICKED_UP) {
      throw new AppError(`Cannot start delivery from ${delivery.status} status`, 400);
    }

    const updated = await prisma.delivery.update({
      where: { id: deliveryId },
      data: { status: DeliveryStatus.OUT_FOR_DELIVERY },
      include: INCLUDE_FULL_DELIVERY,
    });
    await OrderService.updateOrderStatus(delivery.orderId, OrderStatus.OUT_FOR_DELIVERY);
    return updated;
  }

  static async markDelivered(deliveryId: string, riderId: string) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    if (delivery.status !== DeliveryStatus.OUT_FOR_DELIVERY) {
      throw new AppError(`Cannot mark delivered from ${delivery.status} status`, 400);
    }

    const updated = await prisma.delivery.update({
      where: { id: deliveryId },
      data: { status: DeliveryStatus.DELIVERED, deliveredAt: new Date() },
      include: INCLUDE_FULL_DELIVERY,
    });
    await OrderService.updateOrderStatus(delivery.orderId, OrderStatus.DELIVERED);
    await prisma.rider.update({ where: { id: riderId }, data: { status: RiderStatus.ONLINE } });
    return updated;
  }

  static async markFailed(deliveryId: string, riderId: string, reason?: string) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    const terminal: DeliveryStatus[] = [DeliveryStatus.DELIVERED, DeliveryStatus.FAILED];
    if (terminal.includes(delivery.status)) {
      throw new AppError(`Cannot fail a delivery already in ${delivery.status} status`, 400);
    }

    const updated = await prisma.delivery.update({
      where: { id: deliveryId },
      data: { status: DeliveryStatus.FAILED, notes: reason },
      include: INCLUDE_FULL_DELIVERY,
    });
    await OrderService.updateOrderStatus(delivery.orderId, OrderStatus.CANCELLED, reason);
    await prisma.rider.update({ where: { id: riderId }, data: { status: RiderStatus.ONLINE } });
    return updated;
  }
}
