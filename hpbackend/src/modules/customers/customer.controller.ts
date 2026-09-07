// ============================================================
// HungerPoint Backend — Customer Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { CustomerService } from './customer.service';

export class CustomerController {
  static async getAddresses(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const addresses = await CustomerService.getAddresses(customer.id);
      res.json({ success: true, data: addresses });
    } catch (error) {
      next(error);
    }
  }

  static async addAddress(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const address = await CustomerService.addAddress(customer.id, req.body);
      res.status(201).json({ success: true, message: 'Address added successfully', data: address });
    } catch (error) {
      next(error);
    }
  }

  static async updateAddress(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const address = await CustomerService.updateAddress(req.params.id as string, customer.id, req.body);
      res.json({ success: true, message: 'Address updated successfully', data: address });
    } catch (error) {
      next(error);
    }
  }

  static async deleteAddress(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      await CustomerService.deleteAddress(req.params.id as string, customer.id);
      res.json({ success: true, message: 'Address deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  static async getProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const profile = await CustomerService.getProfile(userId);
      res.json({ success: true, data: profile });
    } catch (error) {
      next(error);
    }
  }

  static async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const profile = await CustomerService.updateProfile(userId, req.body);
      res.json({ success: true, message: 'Profile updated successfully', data: profile });
    } catch (error) {
      next(error);
    }
  }
}
