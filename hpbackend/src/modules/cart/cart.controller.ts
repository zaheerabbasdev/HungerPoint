// ============================================================
// HungerPoint — Cart Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { CartService } from './cart.service';
import { CustomerService } from '../customers/customer.service';

export class CartController {
  static async getCart(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const cart = await CartService.getCartByCustomerId(customer.id);
      res.json({ success: true, data: cart });
    } catch (error) {
      next(error);
    }
  }

  static async addItem(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      const item = await CartService.addItem(customer.id, req.body);
      res.status(201).json({ success: true, message: 'Item added to cart', data: item });
    } catch (error) {
      next(error);
    }
  }

  static async updateQuantity(req: Request, res: Response, next: NextFunction) {
    try {
      const { quantity } = req.body;
      const item = await CartService.updateItemQuantity(req.params.itemId as string, Number(quantity));
      res.json({ success: true, message: 'Cart item updated', data: item });
    } catch (error) {
      next(error);
    }
  }

  static async removeItem(req: Request, res: Response, next: NextFunction) {
    try {
      await CartService.removeItem(req.params.itemId as string);
      res.json({ success: true, message: 'Item removed from cart' });
    } catch (error) {
      next(error);
    }
  }

  static async clearCart(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const customer = await CustomerService.getOrCreateCustomer(userId);
      await CartService.clearCart(customer.id);
      res.json({ success: true, message: 'Cart cleared successfully' });
    } catch (error) {
      next(error);
    }
  }
}
