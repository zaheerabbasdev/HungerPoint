// ============================================================
// HungerPoint — Branch Service
// ============================================================

import { prisma } from '../../config/database';

export class BranchService {
  static async getAllBranches(includeInactive = false) {
    return prisma.branch.findMany({
      where: includeInactive ? {} : { isActive: true },
      include: {
        branchHours: true,
        deliveryZones: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  static async getBranchById(id: string) {
    const branch = await prisma.branch.findUnique({
      where: { id },
      include: {
        branchHours: { orderBy: { dayOfWeek: 'asc' } },
        deliveryZones: { where: { isActive: true } },
        branchProducts: {
          include: { product: { include: { variants: true } } },
        },
      },
    });

    if (!branch) {
      const error: any = new Error('Branch not found');
      error.statusCode = 404;
      throw error;
    }

    return branch;
  }

  static async createBranch(data: {
    name: string;
    code: string;
    address: string;
    city: string;
    area?: string;
    latitude: number;
    longitude: number;
    phone?: string;
    email?: string;
    deliveryRadius?: number;
  }) {
    const existing = await prisma.branch.findUnique({ where: { code: data.code } });
    if (existing) {
      const error: any = new Error('Branch with this code already exists');
      error.statusCode = 400;
      throw error;
    }

    return prisma.branch.create({ data });
  }

  static async updateBranch(id: string, data: any) {
    await this.getBranchById(id);
    return prisma.branch.update({ where: { id }, data });
  }

  static async deleteBranch(id: string) {
    await this.getBranchById(id);
    return prisma.branch.delete({ where: { id } });
  }
}
