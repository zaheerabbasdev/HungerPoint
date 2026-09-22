// ============================================================
// HungerPoint — Restaurant Table Service
// ============================================================

import { prisma } from '../../config/database';
import { TableStatus } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

const ACTIVE_ORDER_STATUSES = ['PENDING', 'CONFIRMED', 'ACCEPTED', 'PREPARING', 'READY'];

export class TableService {
  static async getTables(branchId?: string) {
    return prisma.restaurantTable.findMany({
      where: { isActive: true, ...(branchId ? { branchId } : {}) },
      orderBy: { number: 'asc' },
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
      },
    });
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
      },
    });
    if (!table) throw new AppError('Table not found', 404);
    return table;
  }

  static async createTable(data: { branchId: string; number: string; capacity?: number }) {
    return prisma.restaurantTable.create({
      data: {
        branchId: data.branchId,
        number: data.number,
        capacity: data.capacity ?? 4,
      },
    });
  }

  static async updateTable(id: string, data: { number?: string; capacity?: number; status?: TableStatus; isActive?: boolean }) {
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
