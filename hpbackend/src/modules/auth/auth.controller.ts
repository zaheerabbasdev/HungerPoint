// ============================================================
// HungerPoint — Auth Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import * as AuthService from './auth.service';
import { sendSuccess, sendCreated, sendBadRequest } from '../../utils/response';

// ─── Validation Rules ─────────────────────────────────────────
export const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ min: 2, max: 100 }),
  body('phone').trim().notEmpty().withMessage('Phone is required').isMobilePhone('any'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('email').optional().isEmail().withMessage('Invalid email').normalizeEmail(),
];

export const loginValidation = [
  body('phone').trim().notEmpty().withMessage('Phone is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

// ─── Validate Middleware ──────────────────────────────────────
const validate = (req: Request, res: Response): boolean => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    sendBadRequest(res, 'Validation failed', errors.array());
    return false;
  }
  return true;
};

// ─── Register ─────────────────────────────────────────────────
export const register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!validate(req, res)) return;
    const result = await AuthService.registerCustomer(req.body);
    sendCreated(res, result, 'Registration successful');
  } catch (error) {
    next(error);
  }
};

// ─── Login ────────────────────────────────────────────────────
export const login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!validate(req, res)) return;
    const result = await AuthService.login(req.body);
    sendSuccess(res, result, 'Login successful');
  } catch (error) {
    next(error);
  }
};

// ─── Refresh Token ────────────────────────────────────────────
export const refresh = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      sendBadRequest(res, 'Refresh token is required');
      return;
    }
    const result = await AuthService.refreshAccessToken(refreshToken);
    sendSuccess(res, result, 'Token refreshed');
  } catch (error) {
    next(error);
  }
};

// ─── Logout ───────────────────────────────────────────────────
export const logout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await AuthService.logout(refreshToken);
    }
    sendSuccess(res, null, 'Logged out successfully');
  } catch (error) {
    next(error);
  }
};

// ─── Get Profile ──────────────────────────────────────────────
export const getProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const user = await AuthService.getProfile(req.user!.userId);
    sendSuccess(res, user, 'Profile retrieved');
  } catch (error) {
    next(error);
  }
};

// ─── Change Password ──────────────────────────────────────────
export const changePassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { oldPassword, newPassword } = req.body;
    if (!oldPassword || !newPassword) {
      sendBadRequest(res, 'Old and new passwords are required');
      return;
    }
    await AuthService.changePassword(req.user!.userId, oldPassword, newPassword);
    sendSuccess(res, null, 'Password changed successfully');
  } catch (error) {
    next(error);
  }
};
