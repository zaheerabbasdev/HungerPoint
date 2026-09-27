// ============================================================
// HungerPoint — Order Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { OrderService } from './order.service';
import { OrderStatus, OrderSource } from '@prisma/client';
import { CustomerService } from '../customers/customer.service';
import { AppError } from '../../middleware/error.middleware';

const STAFF_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER', 'BRANCH_STAFF', 'WAITER'];
const BRANCH_SCOPED_ROLES = ['BRANCH_MANAGER', 'BRANCH_STAFF', 'KITCHEN_STAFF', 'WAITER'];
const FINAL_STATUSES = ['DELIVERED', 'COMPLETED', 'CANCELLED', 'REJECTED', 'REFUNDED'];

// Admins see every order; branch staff only their branch's; a customer only
// their own; a rider only the one they're delivering.
const canViewOrder = (user: { userId: string; role: string; branchId?: string }, order: any): boolean => {
  if (user.role === 'SUPER_ADMIN' || user.role === 'ADMIN') return true;
  if (BRANCH_SCOPED_ROLES.includes(user.role)) return !!user.branchId && order.branchId === user.branchId;
  if (user.role === 'CUSTOMER') return order.customer?.userId === user.userId;
  if (user.role === 'RIDER') return order.delivery?.rider?.userId === user.userId;
  return false;
};

export class OrderController {
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const role = (req as any).user?.role;

      let customerId: string | null;
      if (STAFF_ROLES.includes(role)) {
        // Staff placing an order on behalf of a customer (POS/phone/dine-in): honor
        // an explicitly selected customerId, or leave it null for a walk-in with no account.
        customerId = req.body.customerId || null;
      } else {
        // Customers can only ever place orders under their own account.
        const customer = await CustomerService.getOrCreateCustomer(userId);
        customerId = customer.id;
      }

      const source: OrderSource | undefined = Object.values(OrderSource).includes(req.body.source)
        ? req.body.source
        : undefined;

      // A waiter can only ever place orders under their own name — trust the
      // JWT, never a client-supplied waiterId.
      const waiterId = role === 'WAITER' ? userId : undefined;

      const order = await OrderService.createOrder({ ...req.body, customerId, source, waiterId });
      res.status(201).json({ success: true, message: 'Order placed successfully', data: order });
    } catch (error) {
      next(error);
    }
  }

  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const { status, type, tableId, page, limit } = req.query;

      const userId = user.userId || user.id;
      let customerId: string | undefined;
      if (user.role === 'CUSTOMER') {
        const customer = await CustomerService.getOrCreateCustomer(userId);
        customerId = customer.id;
      } else {
        customerId = req.query.customerId as string;
      }

      // Branch-scoped staff (waiters included) can only ever see their own
      // branch's orders, regardless of what branchId the request asks for.
      let branchId: string | undefined = req.query.branchId as string | undefined;
      if (['BRANCH_MANAGER', 'BRANCH_STAFF', 'WAITER'].includes(user.role)) {
        branchId = user.branchId || undefined;
      }

      const result = await OrderService.getOrders({
        customerId,
        branchId: branchId as string,
        tableId: tableId as string,
        status: status as OrderStatus,
        type: type as any,
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
      // 404 rather than 403 so order IDs belonging to others aren't confirmed to exist.
      if (!canViewOrder((req as any).user, order)) {
        throw new AppError('Order not found', 404);
      }
      res.json({ success: true, data: order });
    } catch (error) {
      next(error);
    }
  }

  static async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { status, notes } = req.body;
      const user = (req as any).user;
      const userId = user?.userId;

      if (!Object.values(OrderStatus).includes(status)) {
        throw new AppError(`Invalid order status: ${status}`, 400);
      }

      // Once a rider owns this delivery, status must advance through the
      // delivery lifecycle (accept/pickup/out-for-delivery/deliver) so the
      // Order and Delivery records can't desync — this manual endpoint is
      // only for orders that aren't yet in a rider's hands.
      const existing = await OrderService.getOrderById(req.params.id as string);
      if (BRANCH_SCOPED_ROLES.includes(user.role) && existing.branchId !== user.branchId) {
        throw new AppError('Order not found', 404);
      }
      const delivery = (existing as any).delivery;
      if (delivery?.riderId && !['DELIVERED', 'FAILED'].includes(delivery.status)) {
        throw new AppError('This order is assigned to a rider — status now advances automatically as they accept, pick up, and deliver it.', 400);
      }

      // A finished order is final — editing it back to an earlier status would
      // desync it from a delivery that's already done, or re-trigger side
      // effects like loyalty points on a second DELIVERED/COMPLETED.
      if (FINAL_STATUSES.includes(existing.status)) {
        throw new AppError(`This order is already ${existing.status} and can't be edited further.`, 400);
      }

      const order = await OrderService.updateOrderStatus(req.params.id as string, status, notes, userId);
      res.json({ success: true, message: `Order status updated to ${status}`, data: order });
    } catch (error) {
      next(error);
    }
  }
}
