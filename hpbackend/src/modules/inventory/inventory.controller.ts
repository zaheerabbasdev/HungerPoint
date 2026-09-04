// ============================================================
// HungerPoint — Inventory Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { InventoryService } from './inventory.service';

export class InventoryController {
  static async getStock(req: Request, res: Response, next: NextFunction) {
    try {
      const branchId = req.params.branchId as string || (req as any).user?.branchId;
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
      const createdBy = (req as any).user?.id;
      const updated = await InventoryService.updateStock({ ...req.body, createdBy });
      res.json({ success: true, message: 'Stock updated successfully', data: updated });
    } catch (error) {
      next(error);
    }
  }
}
