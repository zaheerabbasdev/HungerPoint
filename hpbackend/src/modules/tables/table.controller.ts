// ============================================================
// HungerPoint — Restaurant Table Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { TableService } from './table.service';

export class TableController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      // Branch-scoped roles (waiter included) can only ever see their own branch's tables.
      let branchId = req.query.branchId as string | undefined;
      if (['BRANCH_MANAGER', 'BRANCH_STAFF', 'WAITER'].includes(user?.role)) {
        branchId = user.branchId || undefined;
      }
      const tables = await TableService.getTables(branchId);
      res.json({ success: true, count: tables.length, data: tables });
    } catch (error) {
      next(error);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const table = await TableService.getTableById(req.params.id as string);
      res.json({ success: true, data: table });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const table = await TableService.createTable(req.body);
      res.status(201).json({ success: true, message: 'Table created successfully', data: table });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const table = await TableService.updateTable(req.params.id as string, req.body);
      res.json({ success: true, message: 'Table updated successfully', data: table });
    } catch (error) {
      next(error);
    }
  }

  static async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await TableService.deleteTable(req.params.id as string);
      res.json({ success: true, message: 'Table deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
}
