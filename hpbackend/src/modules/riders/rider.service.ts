// ============================================================
// HungerPoint — Rider Service
// ============================================================

import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { RiderStatus, DeliveryStatus, OrderStatus, UserRole } from '@prisma/client';
import { emitToUser, emitToBranchRiders, SOCKET_EVENTS } from '../../sockets';
import { EtaService } from '../orders/eta.service';
import { OrderService } from '../orders/order.service';
import { AppError } from '../../middleware/error.middleware';
import { requireEmail, requirePhone } from '../../utils/identity';
import { assertIdentityAvailable } from '../users/account-identity';
import { assertBranchAvailable } from '../branches/branch-guard';

const SALT_ROUNDS = 12;

// Live-ETA refresh is limited per rider: the routing server is asked about once a minute.
const ETA_REFRESH_EVERY_MS = 60_000;
const lastEtaRefresh = new Map<string, number>();

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
    if (!data.password || data.password.length < 8) throw new AppError('Password must be at least 8 characters', 400);
    if (data.branchId) await assertBranchAvailable(data.branchId);
    await assertIdentityAvailable({ email, phone });
    const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);

    // User and rider profile are created together or not at all.
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: { name: data.name, phone, email, password: hashedPassword, role: UserRole.RIDER, branchId: data.branchId, isVerified: true },
      });
      return tx.rider.create({
        data: { userId: user.id, branchId: data.branchId, vehicle: data.vehicle, licensePlate: data.licensePlate },
        include: { user: { select: { id: true, name: true, phone: true, email: true } }, branch: { select: { name: true } } },
      });
    });
  }

  static async updateRider(
    id: string,
    data: {
      name?: string; email?: string; phone?: string; password?: string;
      vehicle?: string; licensePlate?: string; branchId?: string; isActive?: boolean;
    },
  ) {
    const rider = await prisma.rider.findUnique({ where: { id }, select: { userId: true } });
    if (!rider) throw new AppError('Rider not found', 404);

    // Sign-in details live on the user account behind the rider profile.
    const userData: { name?: string; email?: string; phone?: string; password?: string } = {};
    if (data.name !== undefined) {
      if (!data.name.trim()) throw new AppError('Name cannot be empty', 400);
      userData.name = data.name.trim();
    }
    if (data.email !== undefined) userData.email = requireEmail(data.email);
    if (data.phone !== undefined) userData.phone = requirePhone(data.phone);
    if (data.password) {
      if (data.password.length < 8) throw new AppError('Password must be at least 8 characters', 400);
      userData.password = await bcrypt.hash(data.password, SALT_ROUNDS);
    }
    if (data.branchId) await assertBranchAvailable(data.branchId);
    await assertIdentityAvailable({ email: userData.email, phone: userData.phone }, rider.userId);

    const { vehicle, licensePlate, branchId, isActive } = data;
    return prisma.$transaction(async (tx) => {
      if (Object.keys(userData).length > 0) {
        await tx.user.update({ where: { id: rider.userId }, data: userData });
      }
      // A rider's branch is kept on both records; the user's isActive follows the profile's.
      if (branchId !== undefined || isActive !== undefined) {
        await tx.user.update({ where: { id: rider.userId }, data: { ...(branchId !== undefined ? { branchId } : {}), ...(isActive !== undefined ? { isActive } : {}) } });
      }
      return tx.rider.update({
        where: { id },
        data: { vehicle, licensePlate, branchId, isActive },
        include: { user: { select: { id: true, name: true, phone: true, email: true } }, branch: { select: { name: true } } },
      });
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
    const location = await prisma.riderLocation.create({
      data: {
        riderId,
        latitude,
        longitude,
        heading,
        speed,
      },
    });
    void this.refreshEta(riderId, latitude, longitude);
    return location;
  }

  // While the rider is on the way, the customer's countdown follows the rider's real
  // position (the customer never sees the position itself, only the time).
  private static async refreshEta(riderId: string, latitude: number, longitude: number) {
    const last = lastEtaRefresh.get(riderId) ?? 0;
    if (Date.now() - last < ETA_REFRESH_EVERY_MS) return;
    lastEtaRefresh.set(riderId, Date.now());
    try {
      const delivery = await prisma.delivery.findFirst({
        where: { riderId, status: { in: [DeliveryStatus.PICKED_UP, DeliveryStatus.OUT_FOR_DELIVERY] } },
        select: { orderId: true },
      });
      if (delivery) void EtaService.refresh(delivery.orderId, { latitude, longitude });
    } catch (err) {
      console.error('ETA refresh failed:', err);
    }
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
    if (order.branchId) emitToBranchRiders(order.branchId, SOCKET_EVENTS.RIDER_POOL_UPDATED, { orderId, status: OrderStatus.ASSIGNED, takenBy: riderId });

    return delivery;
  }
}
