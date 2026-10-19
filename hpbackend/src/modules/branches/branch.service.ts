// ============================================================
// HungerPoint — Branch Service
// ============================================================

import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { distanceKm } from '../../utils/eta';

export class BranchService {
  /**
   * Active branches sorted by straight-line distance from a point, each with
   * whether that point is inside its delivery radius. Used to send a delivery
   * order to the branch that can actually reach the customer.
   */
  static async findNearest(latitude: number, longitude: number) {
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || Math.abs(latitude) > 90 || Math.abs(longitude) > 180) {
      throw new AppError('A valid latitude and longitude are required', 400);
    }
    const branches = await prisma.branch.findMany({
      where: { isActive: true },
      select: { id: true, name: true, code: true, address: true, area: true, city: true, latitude: true, longitude: true, deliveryRadius: true, isOpen: true },
    });
    return branches
      .map((b) => {
        const km = distanceKm(latitude, longitude, Number(b.latitude), Number(b.longitude));
        const radius = Number(b.deliveryRadius);
        return { ...b, distanceKm: Math.round(km * 10) / 10, delivers: radius <= 0 || km <= radius };
      })
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }

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
      throw new AppError('Branch not found', 404);
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
      throw new AppError('Branch with this code already exists', 400);
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
