// ============================================================
// HungerPoint — Kitchen Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { KitchenService } from './kitchen.service';

export class KitchenController {
  static async getQueue(req: Request, res: Response, next: NextFunction) {
    try {
      const branchId = req.query.branchId as string || (req as any).user?.branchId;
      const orders = await KitchenService.getActiveKitchenQueue(branchId);
      res.json({ success: true, count: orders.length, data: orders });
    } catch (error) {
      next(error);
    }
  }

  static async startPreparing(req: Request, res: Response, next: NextFunction) {
    try {
      const { estimatedPrepTime } = req.body;
      const order = await KitchenService.markOrderAsPreparing(req.params.id as string, Number(estimatedPrepTime) || 15);
      res.json({ success: true, message: 'Order preparation started', data: order });
    } catch (error) {
      next(error);
    }
  }

  static async markReady(req: Request, res: Response, next: NextFunction) {
    try {
      const order = await KitchenService.markOrderAsReady(req.params.id as string);
      res.json({ success: true, message: 'Order marked as ready', data: order });
    } catch (error) {
      next(error);
    }
  }
}
