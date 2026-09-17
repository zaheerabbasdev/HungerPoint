// ============================================================
// HungerPoint — Rider Service
// ============================================================

import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { RiderStatus, DeliveryStatus, OrderStatus, UserRole } from '@prisma/client';
import { emitToUser, SOCKET_EVENTS } from '../../sockets';
import { OrderService } from '../orders/order.service';

const SALT_ROUNDS = 12;

export class RiderService {
  static async createRider(data: {
    name: string;
    phone: string;
    password: string;
    branchId?: string;
    vehicle?: string;
    licensePlate?: string;
  }) {
    const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);
    const user = await prisma.user.create({
      data: {
        name: data.name,
        phone: data.phone,
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
      include: { user: { select: { id: true, name: true, phone: true } }, branch: { select: { name: true } } },
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
    if (!rider) throw new Error('Rider profile not found for this account');
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
    if (!rider) throw new Error('Rider profile not found for this account');
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
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new Error('Order not found');

    const rider = await prisma.rider.findUnique({ where: { id: riderId } });
    if (!rider) throw new Error('Rider not found');

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
