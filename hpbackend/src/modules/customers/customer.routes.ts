// ============================================================
// HungerPoint Backend — Customer Routes
// ============================================================

import { Router } from 'express';
import { CustomerController } from './customer.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

// All customer routes require authentication
router.use(authenticate);

// Profile
router.get('/profile', CustomerController.getProfile);
router.put('/profile', CustomerController.updateProfile);

// Addresses
router.get('/addresses', CustomerController.getAddresses);
router.post('/addresses', CustomerController.addAddress);
router.put('/addresses/:id', CustomerController.updateAddress);
router.delete('/addresses/:id', CustomerController.deleteAddress);

export default router;
