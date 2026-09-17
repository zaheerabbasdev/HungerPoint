// ============================================================
// HungerPoint — Report Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReportService } from './report.service';

export class ReportController {
  static resolveBranchId(req: Request): string | undefined {
    const user = (req as any).user;
    if (user.role === 'BRANCH_MANAGER') return user.branchId || undefined;
    return req.query.branchId as string | undefined;
  }

  static async getOverview(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getDashboardOverview(ReportController.resolveBranchId(req));
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getOrdersByStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getOrdersByStatus(ReportController.resolveBranchId(req));
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getTopProducts(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getTopProducts(ReportController.resolveBranchId(req));
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getOrdersBySource(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getOrdersBySource(ReportController.resolveBranchId(req));
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}
