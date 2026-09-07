// ============================================================
// HungerPoint — Order Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { OrderService } from './order.service';
import { OrderStatus } from '@prisma/client';
import { CustomerService } from '../customers/customer.service';

export class OrderController {
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const customerId = customer.id;
      const order = await OrderService.createOrder({ ...req.body, customerId });
      res.status(201).json({ success: true, message: 'Order placed successfully', data: order });
    } catch (error) {
      next(error);
    }
  }

  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const { branchId, status, page, limit } = req.query;

      const userId = user.userId || user.id;
      let customerId: string | undefined;
      if (user.role === 'CUSTOMER') {
        const customer = await CustomerService.getOrCreateCustomer(userId);
        customerId = customer.id;
      } else {
        customerId = req.query.customerId as string;
      }

      const result = await OrderService.getOrders({
        customerId,
        branchId: branchId as string,
        status: status as OrderStatus,
        page: Number(page) || 1,
        limit: Number(limit) || 20,
      });

      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const order = await OrderService.getOrderById(req.params.id as string);
      res.json({ success: true, data: order });
    } catch (error) {
      next(error);
    }
  }

  static async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { status, notes } = req.body;
      const userId = (req as any).user?.id;
      const order = await OrderService.updateOrderStatus(req.params.id as string, status, notes, userId);
      res.json({ success: true, message: `Order status updated to ${status}`, data: order });
    } catch (error) {
      next(error);
    }
  }
}
