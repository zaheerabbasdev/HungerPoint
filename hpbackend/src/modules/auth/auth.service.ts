// ============================================================
// HungerPoint — Auth Service
// ============================================================

import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { AuthPayload } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const SALT_ROUNDS = 12;

// ─── Token Helpers ────────────────────────────────────────────
const generateAccessToken = (payload: AuthPayload): string =>
  jwt.sign(payload, process.env.JWT_SECRET as string, {
    expiresIn: (process.env.JWT_EXPIRES_IN || '15m') as jwt.SignOptions['expiresIn'],
  });

const generateRefreshToken = (payload: AuthPayload): string =>
  jwt.sign(payload, process.env.JWT_REFRESH_SECRET as string, {
    expiresIn: (process.env.JWT_REFRESH_EXPIRES_IN || '7d') as jwt.SignOptions['expiresIn'],
  });

// ─── Register Customer ────────────────────────────────────────
export const registerCustomer = async (data: {
  name: string;
  phone: string;
  email?: string;
  password: string;
  dateOfBirth?: string;
}) => {
  const exists = await prisma.user.findUnique({ where: { phone: data.phone } });
  if (exists) throw new AppError('Phone number already registered', 409);

  if (data.email) {
    const emailExists = await prisma.user.findUnique({ where: { email: data.email } });
    if (emailExists) throw new AppError('Email already registered', 409);
  }

  const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);

  const user = await prisma.user.create({
    data: {
      name: data.name,
      phone: data.phone,
      email: data.email,
      password: hashedPassword,
      role: UserRole.CUSTOMER,
      customer: {
        create: {
          dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
          loyaltyAccount: { create: {} },
        },
      },
    },
    select: {
      id: true, name: true, phone: true, email: true, role: true, isVerified: true, createdAt: true,
    },
  });

  const payload: AuthPayload = { userId: user.id, role: user.role };
  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  // Store refresh token
  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { user, accessToken, refreshToken };
};

// ─── Login ────────────────────────────────────────────────────
export const login = async (data: { phone: string; password: string }) => {
  const user = await prisma.user.findUnique({
    where: { phone: data.phone },
    select: {
      id: true, name: true, phone: true, email: true,
      role: true, isActive: true, isVerified: true,
      password: true, branchId: true, profileImage: true,
    },
  });

  if (!user) throw new AppError('Invalid phone number or password', 401);
  if (!user.isActive) throw new AppError('Account has been deactivated', 403);

  const isPasswordValid = await bcrypt.compare(data.password, user.password);
  if (!isPasswordValid) throw new AppError('Invalid phone number or password', 401);

  const payload: AuthPayload = {
    userId: user.id,
    role: user.role,
    branchId: user.branchId ?? undefined,
  };

  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  const { password: _, ...userWithoutPassword } = user;
  return { user: userWithoutPassword, accessToken, refreshToken };
};

// ─── Refresh Token ────────────────────────────────────────────
export const refreshAccessToken = async (token: string) => {
  const stored = await prisma.refreshToken.findUnique({ where: { token } });
  if (!stored || stored.expiresAt < new Date()) {
    throw new AppError('Invalid or expired refresh token', 401);
  }

  let decoded: AuthPayload;
  try {
    decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET!) as AuthPayload;
  } catch {
    throw new AppError('Invalid refresh token', 401);
  }

  const user = await prisma.user.findUnique({
    where: { id: decoded.userId },
    select: { id: true, role: true, isActive: true, branchId: true },
  });

  if (!user || !user.isActive) throw new AppError('User not found or inactive', 401);

  const payload: AuthPayload = {
    userId: user.id,
    role: user.role,
    branchId: user.branchId ?? undefined,
  };

  const accessToken = generateAccessToken(payload);
  const newRefreshToken = generateRefreshToken(payload);

  // Rotate refresh token
  await prisma.refreshToken.delete({ where: { token } });
  await prisma.refreshToken.create({
    data: {
      token: newRefreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { accessToken, refreshToken: newRefreshToken };
};

// ─── Logout ───────────────────────────────────────────────────
export const logout = async (token: string): Promise<void> => {
  await prisma.refreshToken.deleteMany({ where: { token } });
};

// ─── Get Profile ──────────────────────────────────────────────
export const getProfile = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true, name: true, phone: true, email: true,
      role: true, isActive: true, isVerified: true,
      profileImage: true, createdAt: true,
      customer: {
        select: {
          dateOfBirth: true, totalOrders: true, totalSpent: true,
          loyaltyAccount: { select: { points: true, lifetime: true } },
        },
      },
    },
  });

  if (!user) throw new AppError('User not found', 404);
  return user;
};

// ─── Change Password ──────────────────────────────────────────
export const changePassword = async (userId: string, oldPassword: string, newPassword: string): Promise<void> => {
  const user = await prisma.user.findUnique({ where: { id: userId }, select: { password: true } });
  if (!user) throw new AppError('User not found', 404);

  const isValid = await bcrypt.compare(oldPassword, user.password);
  if (!isValid) throw new AppError('Current password is incorrect', 401);

  const hashed = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await prisma.user.update({ where: { id: userId }, data: { password: hashed } });

  // Invalidate all refresh tokens
  await prisma.refreshToken.deleteMany({ where: { userId } });
};
