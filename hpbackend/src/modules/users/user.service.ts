// ============================================================
// HungerPoint — User (Staff Account) Service
// ============================================================

import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { UserRole } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';
import { requireEmail, requirePhone } from '../../utils/identity';
import { assertIdentityAvailable } from './account-identity';
import { assertBranchAvailable } from '../branches/branch-guard';

const SALT_ROUNDS = 12;
const STAFF_ROLES: UserRole[] = [
  UserRole.ADMIN,
  UserRole.BRANCH_MANAGER,
  UserRole.BRANCH_STAFF,
  UserRole.KITCHEN_STAFF,
  UserRole.WAITER,
];
// These roles only ever see their own branch's data, so they need one.
const BRANCH_ROLES: UserRole[] = [
  UserRole.BRANCH_MANAGER,
  UserRole.BRANCH_STAFF,
  UserRole.KITCHEN_STAFF,
  UserRole.WAITER,
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

  static async createStaffUser(
    data: { name: string; phone: string; password: string; role: UserRole; branchId?: string; email: string }
  ) {
    if (!STAFF_ROLES.includes(data.role)) {
      throw new AppError('Invalid staff role', 400);
    }
    if (BRANCH_ROLES.includes(data.role) && !data.branchId) {
      throw new AppError('Please choose a branch for this staff account', 400);
    }
    const email = requireEmail(data.email);
    const phone = requirePhone(data.phone);
    if (data.branchId) await assertBranchAvailable(data.branchId);
    await assertIdentityAvailable({ email, phone });
    const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);
    return prisma.user.create({
      data: {
        name: data.name,
        phone,
        email,
        password: hashedPassword,
        role: data.role,
        branchId: data.branchId,
        isVerified: true,
      },
      select: { id: true, name: true, phone: true, email: true, role: true, isActive: true, branchId: true },
    });
  }

  static async updateStaffUser(
    id: string,
    data: { role?: UserRole; branchId?: string | null; isActive?: boolean }
  ) {
    const target = await prisma.user.findUnique({ where: { id }, select: { role: true } });
    if (!target) {
      throw new AppError('Staff account not found', 404);
    }

    return prisma.user.update({
      where: { id },
      data,
      select: { id: true, name: true, phone: true, email: true, role: true, isActive: true, branchId: true },
    });
  }
}
