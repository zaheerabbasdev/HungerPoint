// ============================================================
// HungerPoint — Inventory Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { InventoryService } from './inventory.service';

export class InventoryController {
  static async getAllItems(req: Request, res: Response, next: NextFunction) {
    try {
      const items = await InventoryService.getAllItems();
      res.json({ success: true, count: items.length, data: items });
    } catch (error) {
      next(error);
    }
  }

  static async getStock(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const branchId = user.role === 'BRANCH_MANAGER'
        ? user.branchId
        : (req.params.branchId as string || user?.branchId);
      const stock = await InventoryService.getBranchInventory(branchId);
      res.json({ success: true, count: stock.length, data: stock });
    } catch (error) {
      next(error);
    }
  }

  static async addItem(req: Request, res: Response, next: NextFunction) {
    try {
      const item = await InventoryService.addInventoryItem(req.body);
      res.status(201).json({ success: true, message: 'Inventory item added', data: item });
    } catch (error) {
      next(error);
    }
  }

  static async updateStock(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const createdBy = user?.userId || user?.id;
      const branchId = user.role === 'BRANCH_MANAGER' ? user.branchId : req.body.branchId;
      const updated = await InventoryService.updateStock({ ...req.body, branchId, createdBy });
      res.json({ success: true, message: 'Stock updated successfully', data: updated });
    } catch (error) {
      next(error);
    }
  }
}
