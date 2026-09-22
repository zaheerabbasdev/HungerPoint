// ============================================================
// HungerPoint — Restaurant Table Service
// ============================================================

import { prisma } from '../../config/database';
import { TableStatus } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

const ACTIVE_ORDER_STATUSES = ['PENDING', 'CONFIRMED', 'ACCEPTED', 'PREPARING', 'READY'];

const RESERVATION_INCLUDE = {
  where: { status: 'UPCOMING' as const },
  orderBy: { reservedFor: 'asc' as const },
  take: 1,
};

export class TableService {
  static async getTables(branchId?: string, floor?: string) {
    return prisma.restaurantTable.findMany({
      where: { isActive: true, ...(branchId ? { branchId } : {}), ...(floor ? { floor } : {}) },
      orderBy: [{ floor: 'asc' }, { number: 'asc' }],
      include: {
        orders: {
          where: { status: { in: ACTIVE_ORDER_STATUSES as any } },
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: {
            items: { include: { product: true, variant: true, addons: true } },
            waiter: { select: { id: true, name: true } },
          },
        },
        reservations: RESERVATION_INCLUDE,
      },
    });
  }

  /** Distinct floor names for a branch, in table-order — drives the floor selector UI. */
  static async getFloors(branchId: string) {
    const tables = await prisma.restaurantTable.findMany({
      where: { branchId, isActive: true },
      select: { floor: true },
      distinct: ['floor'],
      orderBy: { floor: 'asc' },
    });
    return tables.map((t) => t.floor);
  }

  static async getTableById(id: string) {
    const table = await prisma.restaurantTable.findUnique({
      where: { id },
      include: {
        orders: {
          where: { status: { in: ACTIVE_ORDER_STATUSES as any } },
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: {
            items: { include: { product: true, variant: true, addons: true } },
            statusHistory: { orderBy: { createdAt: 'asc' } },
            waiter: { select: { id: true, name: true } },
          },
        },
        reservations: RESERVATION_INCLUDE,
      },
    });
    if (!table) throw new AppError('Table not found', 404);
    return table;
  }

  static async createTable(data: { branchId: string; number: string; floor?: string; capacity?: number }) {
    return prisma.restaurantTable.create({
      data: {
        branchId: data.branchId,
        number: data.number,
        floor: data.floor || 'Ground Floor',
        capacity: data.capacity ?? 4,
      },
    });
  }

  static async updateTable(id: string, data: { number?: string; floor?: string; capacity?: number; status?: TableStatus; isActive?: boolean }) {
    await this.getTableById(id);
    return prisma.restaurantTable.update({ where: { id }, data });
  }

  static async deleteTable(id: string) {
    await this.getTableById(id);
    try {
      return await prisma.restaurantTable.delete({ where: { id } });
    } catch {
      return prisma.restaurantTable.update({ where: { id }, data: { isActive: false } });
    }
  }
}
