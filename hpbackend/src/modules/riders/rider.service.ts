// ============================================================
// HungerPoint — Rider Service
// ============================================================

import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { RiderStatus, DeliveryStatus, OrderStatus, UserRole } from '@prisma/client';
import { emitToUser, SOCKET_EVENTS } from '../../sockets';
import { OrderService } from '../orders/order.service';
import { AppError } from '../../middleware/error.middleware';
import { requireEmail, requirePhone } from '../../utils/identity';

const SALT_ROUNDS = 12;

export class RiderService {
  static async createRider(data: {
    name: string;
    phone: string;
    email: string;
    password: string;
    branchId?: string;
    vehicle?: string;
    licensePlate?: string;
  }) {
    const email = requireEmail(data.email);
    const phone = requirePhone(data.phone);
    const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);
    const user = await prisma.user.create({
      data: {
        name: data.name,
        phone,
        email,
        password: hashedPassword,
        role: UserRole.RIDER,
        branchId: data.branchId,
        isVerified: true,
      },
    });

    return prisma.rider.create({
      data: {
        userId: user.id,
        branchId: data.branchId,
        vehicle: data.vehicle,
        licensePlate: data.licensePlate,
      },
      include: { user: { select: { id: true, name: true, phone: true, email: true } }, branch: { select: { name: true } } },
    });
  }

  static async updateRider(id: string, data: { vehicle?: string; licensePlate?: string; branchId?: string; isActive?: boolean }) {
    return prisma.rider.update({
      where: { id },
      data,
      include: { user: { select: { id: true, name: true, phone: true } }, branch: { select: { name: true } } },
    });
  }

  static async getRiderByUserId(userId: string) {
    const rider = await prisma.rider.findUnique({ where: { userId } });
    if (!rider) throw new AppError('Rider profile not found for this account', 404);
    return rider;
  }

  static async getRiderProfileByUserId(userId: string) {
    const rider = await prisma.rider.findUnique({
      where: { userId },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        branch: { select: { id: true, name: true, address: true } },
      },
    });
    if (!rider) throw new AppError('Rider profile not found for this account', 404);
    return rider;
  }

  static async getAllRiders(query: { branchId?: string; status?: RiderStatus }) {
    const where: any = {};
    if (query.branchId) where.branchId = query.branchId;
    if (query.status) where.status = query.status;

    return prisma.rider.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        branch: { select: { name: true } },
        deliveries: {
          where: { status: { in: [DeliveryStatus.ASSIGNED, DeliveryStatus.ACCEPTED, DeliveryStatus.PICKED_UP] } },
          include: { order: { select: { id: true, orderNumber: true, total: true } } },
        },
      },
    });
  }

  static async updateStatus(riderId: string, status: RiderStatus) {
    return prisma.rider.update({
      where: { id: riderId },
      data: { status },
      include: { user: { select: { name: true, phone: true } } },
    });
  }

  static async updateLocation(riderId: string, latitude: number, longitude: number, heading?: number, speed?: number) {
    return prisma.riderLocation.create({
      data: {
        riderId,
        latitude,
        longitude,
        heading,
        speed,
      },
    });
  }

  static async assignRiderToOrder(orderId: string, riderId: string) {
    const order = await prisma.order.findUnique({ where: { id: orderId }, include: { delivery: true } });
    if (!order) throw new AppError('Order not found', 404);
    if (order.type !== 'DELIVERY') throw new AppError('Only delivery orders can be assigned to a rider', 400);

    // First assignment happens once the kitchen marks the order READY; a
    // reassignment is allowed only until the current rider has picked it up.
    const existing = order.delivery;
    const reassignable = existing && ['ASSIGNED', 'ACCEPTED'].includes(existing.status);
    if (order.status !== OrderStatus.READY && !(order.status === OrderStatus.ASSIGNED && reassignable)) {
      throw new AppError(`Order is ${order.status} — a rider can only be assigned once it is READY and not yet picked up`, 400);
    }

    const rider = await prisma.rider.findUnique({ where: { id: riderId } });
    if (!rider) throw new AppError('Rider not found', 404);
    if (!rider.isActive) throw new AppError('This rider account is inactive', 400);
    if (existing?.riderId === riderId) throw new AppError('This rider is already assigned to the order', 400);

    // Free up the previous rider when the order is handed to someone else.
    if (existing?.riderId && reassignable) {
      await prisma.rider.update({ where: { id: existing.riderId }, data: { status: RiderStatus.ONLINE } });
    }

    const delivery = await prisma.delivery.upsert({
      where: { orderId },
      create: {
        orderId,
        riderId,
        status: DeliveryStatus.ASSIGNED,
      },
      update: {
        riderId,
        status: DeliveryStatus.ASSIGNED,
        acceptedAt: null,
        pickedUpAt: null,
        deliveredAt: null,
      },
      include: {
        rider: { include: { user: { select: { name: true, phone: true } } } },
        order: true,
      },
    });

    await prisma.rider.update({
      where: { id: riderId },
      data: { status: RiderStatus.ON_DELIVERY },
    });

    // Reflect the assignment on the order itself (drives customer tracking + history).
    await OrderService.updateOrderStatus(orderId, OrderStatus.ASSIGNED);

    // Notify the rider's app in real time so a new assignment shows up immediately.
    emitToUser(rider.userId, SOCKET_EVENTS.RIDER_ASSIGNMENT, delivery);

    return delivery;
  }
}
