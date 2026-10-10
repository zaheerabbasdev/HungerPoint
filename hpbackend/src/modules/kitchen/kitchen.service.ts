// ============================================================
// HungerPoint — Kitchen Service
// ============================================================

import { prisma } from '../../config/database';
import { OrderStatus } from '@prisma/client';
import { emitToOrder, emitToKitchen, emitToAdmins, emitToBranchRiders, SOCKET_EVENTS } from '../../sockets';
import { RoutingService } from '../../utils/routing';
import { EtaService } from '../orders/eta.service';
import { CalibrationService } from '../orders/calibration.service';
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

    const prepMinutes = Math.min(180, Math.max(1, Math.round(estimatedPrepTimeMinutes)));
    const { rawRide, ride, promisedPrep, promisedAt } = await this.computePromise(orderId, prepMinutes);
    const now = new Date();

    const order = await prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.PREPARING,
        acceptedAt: now,
        estimatedPrepTime: prepMinutes,
        prepMinutesEntered: prepMinutes,
        promisedPrepMinutes: promisedPrep,
        mapRideMinutes: rawRide,
        estimatedDeliveryTime: ride,
        promisedAt,
        statusHistory: {
          create: {
            status: OrderStatus.PREPARING,
            notes: `Preparation started (${prepMinutes} mins estimated)`,
          },
        },
      },
    });

    emitToOrder(orderId, SOCKET_EVENTS.ORDER_PREPARING, order);
    // Swap the instant estimate for the road-based ride time as soon as it is known.
    void EtaService.refresh(orderId);
    if (order.branchId) emitToKitchen(order.branchId, 'kitchen.queue_updated', order);
    emitToAdmins(SOCKET_EVENTS.ORDER_PREPARING, order);
    if (order.branchId) emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId, status: order.status });

    return order;
  }

  /** Kitchen asks for more time: pushes the promised time (and the customer's countdown) back. */
  static async extendPrepTime(orderId: string, extraMinutes: number, restrictToBranchId?: string) {
    await this.getTicket(orderId, [OrderStatus.PREPARING], restrictToBranchId);
    const extra = Math.min(60, Math.max(1, Math.round(extraMinutes)));
    const current = await prisma.order.findUniqueOrThrow({ where: { id: orderId } });

    const order = await prisma.order.update({
      where: { id: orderId },
      data: {
        estimatedPrepTime: (current.estimatedPrepTime ?? 0) + extra,
        promisedPrepMinutes: (current.promisedPrepMinutes ?? current.estimatedPrepTime ?? 0) + extra,
        promisedAt: new Date((current.promisedAt ?? new Date()).getTime() + extra * 60_000),
        statusHistory: { create: { status: OrderStatus.PREPARING, notes: `Kitchen added ${extra} more minutes` } },
      },
    });

    emitToOrder(orderId, SOCKET_EVENTS.ORDER_ETA_UPDATED, { orderId, promisedAt: order.promisedAt });
    if (order.branchId) {
      emitToKitchen(order.branchId, 'kitchen.queue_updated', order);
      emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId, status: order.status });
    }
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
    if (order.branchId) emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId, status: order.status, ready: true });

    return order;
  }

  // promisedAt = now + prep + ride. Both parts are corrected by how this branch has really performed
  // (see CalibrationService); with too little history the corrections are 1 and nothing changes.
  private static async computePromise(orderId: string, prepMinutes: number) {
    const o = await prisma.order.findUnique({
      where: { id: orderId },
      select: { type: true, branchId: true, branch: { select: { latitude: true, longitude: true } }, address: { select: { latitude: true, longitude: true } } },
    });
    const factors = await CalibrationService.getFactors(o?.branchId);
    const rawRide = o?.type === 'DELIVERY' ? RoutingService.estimateNow(o.branch, o.address) : 0;
    const ride = CalibrationService.applyRide(rawRide, factors);
    const promisedPrep = CalibrationService.applyPrep(prepMinutes, factors);
    return { rawRide, ride, promisedPrep, promisedAt: new Date(Date.now() + (promisedPrep + ride) * 60_000) };
  }
}
