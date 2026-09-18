// ============================================================
// HungerPoint — Order Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { OrderService } from './order.service';
import { OrderStatus, OrderSource } from '@prisma/client';
import { CustomerService } from '../customers/customer.service';
import { AppError } from '../../middleware/error.middleware';

const STAFF_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER', 'BRANCH_STAFF'];

export class OrderController {
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const role = (req as any).user?.role;

      let customerId: string | null;
      if (STAFF_ROLES.includes(role)) {
        // Staff placing an order on behalf of a customer (POS/phone): honor an
        // explicitly selected customerId, or leave it null for a walk-in with no account.
        customerId = req.body.customerId || null;
      } else {
        // Customers can only ever place orders under their own account.
        const customer = await CustomerService.getOrCreateCustomer(userId);
        customerId = customer.id;
      }

      const source: OrderSource | undefined = Object.values(OrderSource).includes(req.body.source)
        ? req.body.source
        : undefined;

      const order = await OrderService.createOrder({ ...req.body, customerId, source });
      res.status(201).json({ success: true, message: 'Order placed successfully', data: order });
    } catch (error) {
      next(error);
    }
  }

  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const { status, page, limit } = req.query;

      const userId = user.userId || user.id;
      let customerId: string | undefined;
      if (user.role === 'CUSTOMER') {
        const customer = await CustomerService.getOrCreateCustomer(userId);
        customerId = customer.id;
      } else {
        customerId = req.query.customerId as string;
      }

      // Branch-scoped staff can only ever see their own branch's orders,
      // regardless of what branchId the request asks for.
      let branchId: string | undefined = req.query.branchId as string | undefined;
      if (['BRANCH_MANAGER', 'BRANCH_STAFF'].includes(user.role)) {
        branchId = user.branchId || undefined;
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

      // Once a rider owns this delivery, status must advance through the
      // delivery lifecycle (accept/pickup/out-for-delivery/deliver) so the
      // Order and Delivery records can't desync — this manual endpoint is
      // only for orders that aren't yet in a rider's hands.
      const existing = await OrderService.getOrderById(req.params.id as string);
      const delivery = (existing as any).delivery;
      if (delivery?.riderId && !['DELIVERED', 'FAILED'].includes(delivery.status)) {
        throw new AppError('This order is assigned to a rider — status now advances automatically as they accept, pick up, and deliver it.', 400);
      }

      const order = await OrderService.updateOrderStatus(req.params.id as string, status, notes, userId);
      res.json({ success: true, message: `Order status updated to ${status}`, data: order });
    } catch (error) {
      next(error);
    }
  }
}
