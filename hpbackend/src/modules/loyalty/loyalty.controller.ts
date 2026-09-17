// ============================================================
// HungerPoint — Loyalty Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { LoyaltyService } from './loyalty.service';
import { CustomerService } from '../customers/customer.service';
import { LoyaltyTransactionType } from '@prisma/client';

export class LoyaltyController {
  /** Customer's own balance + history */
  static async getMyAccount(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const account = await LoyaltyService.getAccountByCustomerId(customer.id);
      res.json({ success: true, data: account });
    } catch (error) {
      next(error);
    }
  }

  /** Admin: list all customer loyalty accounts */
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const accounts = await LoyaltyService.getAllAccounts();
      res.json({ success: true, count: accounts.length, data: accounts });
    } catch (error) {
      next(error);
    }
  }

  /** Admin: view a specific customer's transaction history */
  static async getAccount(req: Request, res: Response, next: NextFunction) {
    try {
      const account = await LoyaltyService.getAccountByCustomerId(req.params.customerId as string);
      res.json({ success: true, data: account });
    } catch (error) {
      next(error);
    }
  }

  /** Admin: manually adjust a customer's points balance */
  static async adjust(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { customerId, points, type, notes } = req.body;
      if (!customerId || !points || !Object.values(LoyaltyTransactionType).includes(type)) {
        res.status(400).json({ success: false, message: 'customerId, points, and a valid type are required' });
        return;
      }
      const account = await LoyaltyService.adjustPoints(customerId, Number(points), type, notes);
      res.json({ success: true, message: 'Loyalty points adjusted', data: account });
    } catch (error) {
      next(error);
    }
  }
}
