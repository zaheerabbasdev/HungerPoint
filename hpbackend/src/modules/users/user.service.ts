// ============================================================
// HungerPoint — User (Staff Account) Service
// ============================================================

import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { UserRole } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

const SALT_ROUNDS = 12;
const STAFF_ROLES: UserRole[] = [
  UserRole.SUPER_ADMIN,
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
    actorRole: UserRole,
    data: { name: string; phone: string; password: string; role: UserRole; branchId?: string; email?: string }
  ) {
    if (!STAFF_ROLES.includes(data.role)) {
      throw new AppError('Invalid staff role', 400);
    }
    // Only a Super Admin can hand out Admin-tier access — an Admin creating
    // another Admin (or a Super Admin) would have no real ceiling on its
    // own privileges.
    if (actorRole !== UserRole.SUPER_ADMIN && (data.role === UserRole.SUPER_ADMIN || data.role === UserRole.ADMIN)) {
      throw new AppError('Only a Super Admin can create Admin or Super Admin accounts', 403);
    }
    if (BRANCH_ROLES.includes(data.role) && !data.branchId) {
      throw new AppError('Please choose a branch for this staff account', 400);
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

  static async updateStaffUser(
    actorRole: UserRole,
    id: string,
    data: { role?: UserRole; branchId?: string | null; isActive?: boolean }
  ) {
    const target = await prisma.user.findUnique({ where: { id }, select: { role: true } });
    if (!target) {
      throw new AppError('Staff account not found', 404);
    }

    // Same ceiling as creation: an Admin can manage Branch Manager/Staff/
    // Kitchen Staff accounts, but never touch an existing Admin or Super
    // Admin account, and never promote anyone into either tier.
    const nextRole = data.role ?? target.role;
    const touchesAdminTier =
      target.role === UserRole.SUPER_ADMIN ||
      target.role === UserRole.ADMIN ||
      nextRole === UserRole.SUPER_ADMIN ||
      nextRole === UserRole.ADMIN;

    if (actorRole !== UserRole.SUPER_ADMIN && touchesAdminTier) {
      throw new AppError('Only a Super Admin can manage Admin or Super Admin accounts', 403);
    }

    return prisma.user.update({
      where: { id },
      data,
      select: { id: true, name: true, phone: true, email: true, role: true, isActive: true, branchId: true },
    });
  }
}
