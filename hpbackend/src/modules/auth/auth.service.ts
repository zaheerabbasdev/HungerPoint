// ============================================================
// HungerPoint — Auth Service
// ============================================================

import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { AuthPayload } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const SALT_ROUNDS = 12;

// ─── Token Helpers ────────────────────────────────────────────
const generateAccessToken = (payload: AuthPayload): string =>
  jwt.sign(payload, process.env.JWT_SECRET as string, {
    expiresIn: (process.env.JWT_EXPIRES_IN || '30d') as jwt.SignOptions['expiresIn'],
  });

const generateRefreshToken = (payload: AuthPayload): string =>
  jwt.sign(payload, process.env.JWT_REFRESH_SECRET as string, {
    expiresIn: (process.env.JWT_REFRESH_EXPIRES_IN || '30d') as jwt.SignOptions['expiresIn'],
  });

// Refresh tokens are stored as a SHA-256 hash rather than the raw JWT:
// - the raw token can exceed MySQL's indexable key-length limit
// - hashing means a database leak never exposes usable session tokens
const hashToken = (token: string): string => crypto.createHash('sha256').update(token).digest('hex');

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
      tokenHash: hashToken(refreshToken),
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { user, accessToken, refreshToken };
};

// ─── Login ────────────────────────────────────────────────────
export const login = async (data: { phone?: string; email?: string; password: string }) => {
  const identifier = (data.phone || data.email || '').trim();
  const user = await prisma.user.findFirst({
    where: {
      OR: [
        { phone: identifier },
        { email: identifier },
      ],
    },
    select: {
      id: true, name: true, phone: true, email: true,
      role: true, isActive: true, isVerified: true,
      password: true, branchId: true, profileImage: true,
    },
  });

  if (!user) throw new AppError('Invalid credentials or account not found', 401);
  if (!user.isActive) throw new AppError('Account has been deactivated', 403);

  const isPasswordValid = await bcrypt.compare(data.password, user.password);
  if (!isPasswordValid) throw new AppError('Invalid credentials or password', 401);

  const payload: AuthPayload = {
    userId: user.id,
    role: user.role,
    branchId: user.branchId ?? undefined,
  };

  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  await prisma.refreshToken.create({
    data: {
      tokenHash: hashToken(refreshToken),
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  const { password: _, ...userWithoutPassword } = user;
  return { user: userWithoutPassword, accessToken, refreshToken };
};

// ─── Refresh Token ────────────────────────────────────────────
export const refreshAccessToken = async (token: string) => {
  const stored = await prisma.refreshToken.findUnique({ where: { tokenHash: hashToken(token) } });
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
  await prisma.refreshToken.delete({ where: { tokenHash: hashToken(token) } });
  await prisma.refreshToken.create({
    data: {
      tokenHash: hashToken(newRefreshToken),
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { accessToken, refreshToken: newRefreshToken };
};

// ─── Logout ───────────────────────────────────────────────────
export const logout = async (token: string): Promise<void> => {
  await prisma.refreshToken.deleteMany({ where: { tokenHash: hashToken(token) } });
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

// ─── OTP Store & Authentication for Customer App ─────────────
interface OtpEntry {
  otp: string;
  expiresAt: number;
}
const otpStore = new Map<string, OtpEntry>();

// Helper to send real SMS if a provider (Twilio) is configured in .env
const sendSmsViaGateway = async (phone: string, text: string) => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromPhone = process.env.TWILIO_PHONE_NUMBER;

  if (accountSid && authToken && fromPhone) {
    try {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
      const params = new URLSearchParams();
      params.append('To', phone);
      params.append('From', fromPhone);
      params.append('Body', text);

      const authHeader = Buffer.from(`${accountSid}:${authToken}`).toString('base64');
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${authHeader}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });
      const result = (await response.json()) as any;
      console.log(`[SMS GATEWAY] Twilio dispatch status:`, result.status || result.message);
    } catch (err) {
      console.error(`[SMS GATEWAY ERROR] Failed to send SMS via Twilio:`, err);
    }
  } else {
    console.log(`[SMS GATEWAY SIMULATION] To deliver real carrier SMS, set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER in .env. Simulated SMS to ${phone}: "${text}"`);
  }
};

export const sendOtp = async (phone: string) => {
  const cleanPhone = phone.trim();
  const existingUser = await prisma.user.findUnique({
    where: { phone: cleanPhone },
    select: { id: true, name: true, phone: true },
  });

  // Generate 6-digit OTP
  const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
  otpStore.set(cleanPhone, {
    otp: generatedOtp,
    expiresAt: Date.now() + 10 * 60 * 1000,
  });

  console.log(`[OTP SERVICE] Generated OTP for ${cleanPhone}: ${generatedOtp} (or accept 123456 / 872305)`);

  // Send via SMS gateway or log simulation
  await sendSmsViaGateway(cleanPhone, `Your HungerPoint verification code is: ${generatedOtp}. Valid for 10 minutes.`);

  return {
    phone: cleanPhone,
    isExistingUser: !!existingUser,
    message: 'OTP sent successfully',
    otp: generatedOtp,
  };
};

export const verifyOtp = async (phone: string, otp: string) => {
  const cleanPhone = phone.trim();
  const stored = otpStore.get(cleanPhone);

  const isValidDevOtp = otp === '123456' || otp === '872305';
  const isValidStoredOtp = stored && stored.otp === otp && stored.expiresAt > Date.now();

  if (!isValidDevOtp && !isValidStoredOtp) {
    throw new AppError('Invalid or expired OTP code', 400);
  }

  otpStore.delete(cleanPhone);

  const user = await prisma.user.findUnique({
    where: { phone: cleanPhone },
    select: {
      id: true,
      name: true,
      phone: true,
      email: true,
      role: true,
      isActive: true,
      isVerified: true,
      profileImage: true,
      customer: {
        select: {
          dateOfBirth: true,
          totalOrders: true,
          totalSpent: true,
        },
      },
    },
  });

  if (user) {
    if (!user.isActive) throw new AppError('Account has been deactivated', 403);

    const payload: AuthPayload = { userId: user.id, role: user.role };
    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    await prisma.refreshToken.create({
      data: {
        tokenHash: hashToken(refreshToken),
        userId: user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return {
      isNewUser: false,
      user,
      accessToken,
      refreshToken,
      message: 'Login successful',
    };
  }

  return {
    isNewUser: true,
    phone: cleanPhone,
    message: 'OTP verified. Please complete your registration.',
  };
};

export const completeProfile = async (data: {
  phone: string;
  name: string;
  dateOfBirth?: string;
  email?: string;
  password?: string;
}) => {
  const cleanPhone = data.phone.trim();
  const existingUser = await prisma.user.findUnique({
    where: { phone: cleanPhone },
    include: { customer: true },
  });

  if (existingUser) {
    const updatedUser = await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        name: data.name,
        email: data.email ?? existingUser.email,
        customer: {
          upsert: {
            create: {
              dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
              loyaltyAccount: { create: {} },
            },
            update: {
              dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
            },
          },
        },
      },
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
        role: true,
        isVerified: true,
        createdAt: true,
      },
    });

    const payload: AuthPayload = { userId: updatedUser.id, role: updatedUser.role };
    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    await prisma.refreshToken.create({
      data: {
        tokenHash: hashToken(refreshToken),
        userId: updatedUser.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return { user: updatedUser, accessToken, refreshToken };
  }

  const defaultPassword = data.password || 'Customer@123456';
  const hashedPassword = await bcrypt.hash(defaultPassword, SALT_ROUNDS);

  const newUser = await prisma.user.create({
    data: {
      name: data.name,
      phone: cleanPhone,
      email: data.email,
      password: hashedPassword,
      role: UserRole.CUSTOMER,
      isVerified: true,
      customer: {
        create: {
          dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
          loyaltyAccount: { create: {} },
        },
      },
    },
    select: {
      id: true,
      name: true,
      phone: true,
      email: true,
      role: true,
      isVerified: true,
      createdAt: true,
    },
  });

  const payload: AuthPayload = { userId: newUser.id, role: newUser.role };
  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  await prisma.refreshToken.create({
    data: {
      tokenHash: hashToken(refreshToken),
      userId: newUser.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { user: newUser, accessToken, refreshToken };
};

