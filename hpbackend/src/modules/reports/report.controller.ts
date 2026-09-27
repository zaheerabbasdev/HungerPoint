// ============================================================
// HungerPoint — Report Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReportService, DateRange } from './report.service';
import { AppError } from '../../middleware/error.middleware';

const MAX_PAGE_SIZE = 100;

const parseDate = (value: unknown, field: string): Date | undefined => {
  if (value === undefined || value === '') return undefined;
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) {
    throw new AppError(`Invalid "${field}" date`, 400);
  }
  return date;
};

const parsePositiveInt = (value: unknown, fallback: number): number => {
  const n = parseInt(String(value ?? ''), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
};

export class ReportController {
  static resolveBranchId(req: Request): string | undefined {
    const user = (req as any).user;
    if (user.role === 'BRANCH_MANAGER') return user.branchId || undefined;
    return (req.query.branchId as string | undefined) || undefined;
  }

  static resolveDateRange(req: Request): DateRange {
    const from = parseDate(req.query.from, 'from');
    const to = parseDate(req.query.to, 'to');
    if (from && to && from > to) {
      throw new AppError('"from" date must be before "to" date', 400);
    }
    return { from, to };
  }

  static async getOverview(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getDashboardOverview(
        ReportController.resolveBranchId(req),
        ReportController.resolveDateRange(req),
      );
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getOrdersByStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getOrdersByStatus(
        ReportController.resolveBranchId(req),
        ReportController.resolveDateRange(req),
      );
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getTopProducts(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getTopProducts(
        ReportController.resolveBranchId(req),
        ReportController.resolveDateRange(req),
      );
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getOrdersBySource(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await ReportService.getOrdersBySource(
        ReportController.resolveBranchId(req),
        ReportController.resolveDateRange(req),
      );
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getOrders(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parsePositiveInt(req.query.page, 1);
      const pageSize = Math.min(parsePositiveInt(req.query.pageSize, 10), MAX_PAGE_SIZE);
      const data = await ReportService.getOrdersPage(
        ReportController.resolveBranchId(req),
        ReportController.resolveDateRange(req),
        page,
        pageSize,
      );
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}
