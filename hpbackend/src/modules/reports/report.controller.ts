// ============================================================
// HungerPoint — Report Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReportService } from './report.service';

export class ReportController {
  static async getOverview(req: Request, res: Response, next: NextFunction) {
    try {
      const branchId = req.query.branchId as string;
      const data = await ReportService.getDashboardOverview(branchId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}
