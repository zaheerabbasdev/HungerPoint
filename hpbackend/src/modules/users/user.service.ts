// ============================================================
// HungerPoint — User (Staff Account) Service
// ============================================================

import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { UserRole } from '@prisma/client';

const SALT_ROUNDS = 12;
const STAFF_ROLES: UserRole[] = [
  UserRole.SUPER_ADMIN,
  UserRole.ADMIN,
  UserRole.BRANCH_MANAGER,
  UserRole.BRANCH_STAFF,
  UserRole.KITCHEN_STAFF,
];

export class UserService {
  static async getStaffUsers() {
    return prisma.user.findMany({
      where: { role: { in: STAFF_ROLES } },
      select: {
        id: true, name: true, phone: true, email: true, role: true,
        isActive: true, branchId: true, createdAt: true,
        branch: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  static async createStaffUser(data: { name: string; phone: string; password: string; role: UserRole; branchId?: string; email?: string }) {
    if (!STAFF_ROLES.includes(data.role)) {
      throw new Error('Invalid staff role');
    }
    const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);
    return prisma.user.create({
      data: {
        name: data.name,
        phone: data.phone,
        email: data.email,
        password: hashedPassword,
        role: data.role,
        branchId: data.branchId,
        isVerified: true,
      },
      select: { id: true, name: true, phone: true, email: true, role: true, isActive: true, branchId: true },
    });
  }

  static async updateStaffUser(id: string, data: { role?: UserRole; branchId?: string | null; isActive?: boolean }) {
    return prisma.user.update({
      where: { id },
      data,
      select: { id: true, name: true, phone: true, email: true, role: true, isActive: true, branchId: true },
    });
  }
}
