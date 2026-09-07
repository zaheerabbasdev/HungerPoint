// ============================================================
// HungerPoint — Auth Routes
// POST /api/v1/auth/register
// POST /api/v1/auth/login
// POST /api/v1/auth/refresh
// POST /api/v1/auth/logout
// GET  /api/v1/auth/me
// PUT  /api/v1/auth/change-password
// ============================================================

import { Router } from 'express';
import * as AuthController from './auth.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

// Public routes
router.post('/register', AuthController.registerValidation, AuthController.register);
router.post('/login',    AuthController.loginValidation,    AuthController.login);
router.post('/send-otp', AuthController.sendOtp);
router.post('/verify-otp', AuthController.verifyOtp);
router.post('/complete-profile', AuthController.completeProfile);
router.post('/refresh',  AuthController.refresh);
router.post('/logout',   AuthController.logout);

// Protected routes
router.get('/me',                   authenticate, AuthController.getProfile);
router.put('/change-password',      authenticate, AuthController.changePassword);

export default router;
