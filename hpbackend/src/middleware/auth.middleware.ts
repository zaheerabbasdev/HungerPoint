// ============================================================
// HungerPoint — JWT Authentication Middleware
// ============================================================

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/database';
import { sendUnauthorized, sendForbidden } from '../utils/response';
import { UserRole } from '@prisma/client';

export interface AuthPayload {
  userId: string;
  role: UserRole;
  branchId?: string;
}

// Extend Express Request to carry auth user
declare global {
  namespace Express {
    interface Request {
      user?: AuthPayload;
    }
  }
}

// ─── Verify JWT Token ────────────────────────────────────────
export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      sendUnauthorized(res, 'No token provided');
      return;
    }

    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET;

    if (!secret) {
      throw new Error('JWT_SECRET not configured');
    }

    const decoded = jwt.verify(token, secret) as AuthPayload;

    // Verify user still exists and is active
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, role: true, isActive: true, branchId: true },
    });

    if (!user) {
      sendUnauthorized(res, 'User no longer exists');
      return;
    }

    if (!user.isActive) {
      sendUnauthorized(res, 'Account has been deactivated');
      return;
    }

    req.user = {
      userId: user.id,
      role: user.role,
      branchId: user.branchId ?? undefined,
    };

    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      sendUnauthorized(res, 'Token expired');
      return;
    }
    if (error instanceof jwt.JsonWebTokenError) {
      sendUnauthorized(res, 'Invalid token');
      return;
    }
    next(error);
  }
};

// ─── Optional Auth (guest-friendly routes) ───────────────────
export const optionalAuth = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  try {
    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET!;
    const decoded = jwt.verify(token, secret) as AuthPayload;

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, role: true, isActive: true, branchId: true },
    });

    if (user && user.isActive) {
      req.user = {
        userId: user.id,
        role: user.role,
        branchId: user.branchId ?? undefined,
      };
    }
  } catch {
    // Ignore auth errors for optional routes
  }

  next();
};

// ─── Role Authorization ──────────────────────────────────────
export const authorize = (...allowedRoles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      sendUnauthorized(res, 'Not authenticated');
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      sendForbidden(res, `Access denied. Required roles: ${allowedRoles.join(', ')}`);
      return;
    }

    next();
  };
};

// ─── Convenient Role Shorthands ──────────────────────────────
export const isAdmin = authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN);
export const isSuperAdmin = authorize(UserRole.SUPER_ADMIN);
export const isBranchManager = authorize(UserRole.BRANCH_MANAGER, UserRole.ADMIN, UserRole.SUPER_ADMIN);
export const isKitchen = authorize(UserRole.KITCHEN_STAFF, UserRole.BRANCH_MANAGER, UserRole.BRANCH_STAFF, UserRole.ADMIN, UserRole.SUPER_ADMIN);
export const isRider = authorize(UserRole.RIDER);
export const isCustomer = authorize(UserRole.CUSTOMER);
export const isStaff = authorize(UserRole.BRANCH_STAFF, UserRole.BRANCH_MANAGER, UserRole.ADMIN, UserRole.SUPER_ADMIN);
