// ============================================================
// HungerPoint Backend — Customer Routes
// ============================================================

import { Router } from 'express';
import { UserRole } from '@prisma/client';
import { CustomerController } from './customer.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';

const router = Router();

// All customer routes require authentication
router.use(authenticate);

// Staff-only: look up an existing customer by phone (POS / phone orders)
router.get(
  '/search',
  authorize(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.BRANCH_MANAGER, UserRole.BRANCH_STAFF),
  CustomerController.searchByPhone
);

// Profile
router.get('/profile', CustomerController.getProfile);
router.put('/profile', CustomerController.updateProfile);
router.delete('/account', CustomerController.deactivateAccount);

// Addresses
router.get('/addresses', CustomerController.getAddresses);
router.post('/addresses', CustomerController.addAddress);
router.put('/addresses/:id', CustomerController.updateAddress);
router.delete('/addresses/:id', CustomerController.deleteAddress);

export default router;
