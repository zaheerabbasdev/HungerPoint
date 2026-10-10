// ============================================================
// HungerPoint — Delivery Service (rider-facing delivery lifecycle)
// ============================================================

import { prisma } from '../../config/database';
import { DeliveryStatus, OrderStatus, OrderType, PaymentMethod, PaymentStatus, RiderStatus, Prisma } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';
import { OrderService } from '../orders/order.service';
import { emitToBranchRiders, emitToOrder, SOCKET_EVENTS } from '../../sockets';
import { travelMinutes } from '../../utils/eta';

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

// Orders that still need a rider: confirmed / being cooked / ready, with nobody on them yet.
const POOL_STATUSES: OrderStatus[] = [OrderStatus.CONFIRMED, OrderStatus.PREPARING, OrderStatus.READY];

export class DeliveryService {
  /**
   * "Upcoming orders" for a rider: their own branch's delivery orders that have no rider yet.
   * Only the customer's area is shown - the exact address and phone stay hidden until the
   * rider has actually taken the order.
   */
  static async getAvailableForRider(riderId: string) {
    const rider = await prisma.rider.findUnique({ where: { id: riderId } });
    if (!rider || !rider.branchId) return [];

    const orders = await prisma.order.findMany({
      where: { branchId: rider.branchId, type: OrderType.DELIVERY, status: { in: POOL_STATUSES }, delivery: null },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true, orderNumber: true, status: true, total: true, paymentMethod: true, paymentStatus: true,
        estimatedPrepTime: true, estimatedDeliveryTime: true, acceptedAt: true, promisedAt: true, readyAt: true, createdAt: true,
        branch: { select: { name: true, address: true } },
        address: { select: { area: true, city: true } },
        _count: { select: { items: true } },
      },
    });

    return orders.map((o) => ({
      ...o,
      // When the food should be ready: cooking start + prep time (null until the kitchen starts).
      readyBy: o.acceptedAt && o.estimatedPrepTime ? new Date(o.acceptedAt.getTime() + o.estimatedPrepTime * 60_000) : null,
      canTake: o.status === OrderStatus.READY,
    }));
  }

  /** A rider takes a READY order. The unique delivery.orderId makes this race-safe: the first insert wins. */
  static async claim(orderId: string, riderId: string) {
    const rider = await prisma.rider.findUnique({ where: { id: riderId } });
    if (!rider || !rider.isActive) throw new AppError('Rider account is inactive', 403);
    if (rider.status !== RiderStatus.ONLINE) {
      throw new AppError(
        rider.status === RiderStatus.ON_DELIVERY ? 'Finish your current delivery before taking another order' : 'Go online to take orders',
        400,
      );
    }

    const order = await prisma.order.findUnique({ where: { id: orderId }, select: { id: true, branchId: true, status: true, type: true } });
    if (!order || order.type !== OrderType.DELIVERY || !rider.branchId || order.branchId !== rider.branchId) {
      throw new AppError('Order not found', 404);
    }
    if (order.status !== OrderStatus.READY) {
      throw new AppError(order.status === OrderStatus.PREPARING || order.status === OrderStatus.CONFIRMED
        ? 'The food is not ready yet' : 'This order is no longer available', 400);
    }

    let delivery;
    try {
      delivery = await prisma.delivery.create({
        data: { orderId, riderId, status: DeliveryStatus.ASSIGNED },
        include: INCLUDE_FULL_DELIVERY,
      });
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        throw new AppError('Another rider already took this order', 409);
      }
      throw err;
    }

    await prisma.rider.update({ where: { id: riderId }, data: { status: RiderStatus.ON_DELIVERY } });
    await OrderService.updateOrderStatus(orderId, OrderStatus.ASSIGNED, 'Rider took the order');
    if (order.branchId) emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId, status: OrderStatus.ASSIGNED, takenBy: riderId });
    return delivery;
  }

  /** The rider gives the order back (before pickup) so another rider can take it. */
  static async release(deliveryId: string, riderId: string) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    if (delivery.status !== DeliveryStatus.ASSIGNED && delivery.status !== DeliveryStatus.ACCEPTED) {
      throw new AppError(`Cannot release a delivery in ${delivery.status} status`, 400);
    }

    await prisma.delivery.delete({ where: { id: deliveryId } });
    await prisma.rider.update({ where: { id: riderId }, data: { status: RiderStatus.ONLINE } });
    const order = await prisma.order.update({
      where: { id: delivery.orderId },
      data: { status: OrderStatus.READY, statusHistory: { create: { status: OrderStatus.READY, notes: 'Rider released the order - back to available' } } },
    });
    if (order.branchId) emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId: order.id, status: OrderStatus.READY, ready: true });
    return { released: true };
  }

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
    // The food is in the rider's hands: the countdown is now just the ride to the customer.
    const route = await prisma.order.findUnique({
      where: { id: delivery.orderId },
      select: { branch: { select: { latitude: true, longitude: true } }, address: { select: { latitude: true, longitude: true } } },
    });
    const minutes = travelMinutes(route?.branch, route?.address);
    const promisedAt = new Date(Date.now() + minutes * 60_000);
    await prisma.order.update({ where: { id: delivery.orderId }, data: { promisedAt, estimatedDeliveryTime: minutes } });
    emitToOrder(delivery.orderId, SOCKET_EVENTS.ORDER_ETA_UPDATED, { orderId: delivery.orderId, promisedAt });
    return updated;
  }

  static async markDelivered(deliveryId: string, riderId: string, cashCollected?: number) {
    const delivery = await this.getOwnedDelivery(deliveryId, riderId);
    if (delivery.status !== DeliveryStatus.OUT_FOR_DELIVERY) {
      throw new AppError(`Cannot mark delivered from ${delivery.status} status`, 400);
    }

    // Handover = payment confirmation. Cash orders must record the money collected;
    // already-paid (online) orders need nothing.
    const order = await prisma.order.findUniqueOrThrow({ where: { id: delivery.orderId } });
    if (order.paymentStatus !== PaymentStatus.PAID) {
      const total = Number(order.total);
      if (order.paymentMethod === PaymentMethod.CASH_ON_DELIVERY) {
        if (cashCollected === undefined || !Number.isFinite(cashCollected)) {
          throw new AppError(`Confirm the cash collected (PKR ${total.toFixed(0)}) before completing the delivery`, 400);
        }
        if (cashCollected < total) {
          throw new AppError(`Collected amount is less than the order total (PKR ${total.toFixed(0)})`, 400);
        }
      }
      const paidAmount = cashCollected ?? total;
      await prisma.order.update({ where: { id: order.id }, data: { paymentStatus: PaymentStatus.PAID, cashCollected: paidAmount } });
      await prisma.payment.upsert({
        where: { orderId: order.id },
        create: { orderId: order.id, method: order.paymentMethod, status: PaymentStatus.PAID, amount: total, paidAmount, paidAt: new Date() },
        update: { status: PaymentStatus.PAID, paidAmount, paidAt: new Date() },
      });
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
