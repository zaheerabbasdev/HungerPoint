// ============================================================
// HungerPoint — Kitchen Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { KitchenService } from './kitchen.service';

// Branch Managers and Kitchen Staff only ever work their own branch's
// tickets; Admins may pick any branch (or all) via ?branchId.
const ownBranchOnly = (req: Request): string | undefined => {
  const user = (req as any).user;
  if (user.role === 'SUPER_ADMIN' || user.role === 'ADMIN') return undefined;
  // Staff with no branch assigned must not fall through to "all branches".
  return user.branchId || '__no_branch__';
};

export class KitchenController {
  static async getQueue(req: Request, res: Response, next: NextFunction) {
    try {
      const branchId = ownBranchOnly(req) ?? ((req.query.branchId as string) || undefined);
      const orders = await KitchenService.getActiveKitchenQueue(branchId);
      res.json({ success: true, count: orders.length, data: orders });
    } catch (error) {
      next(error);
    }
  }

  static async startPreparing(req: Request, res: Response, next: NextFunction) {
    try {
      const { estimatedPrepTime } = req.body;
      const order = await KitchenService.markOrderAsPreparing(
        req.params.id as string,
        Number(estimatedPrepTime) || 15,
        ownBranchOnly(req),
      );
      res.json({ success: true, message: 'Order preparation started', data: order });
    } catch (error) {
      next(error);
    }
  }

  static async markReady(req: Request, res: Response, next: NextFunction) {
    try {
      const order = await KitchenService.markOrderAsReady(req.params.id as string, ownBranchOnly(req));
      res.json({ success: true, message: 'Order marked as ready', data: order });
    } catch (error) {
      next(error);
    }
  }
}
