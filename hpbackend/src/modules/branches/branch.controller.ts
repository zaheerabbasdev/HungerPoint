// ============================================================
// HungerPoint — Branch Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { BranchService } from './branch.service';

export class BranchController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const includeInactive = req.query.includeInactive === 'true';
      const branches = await BranchService.getAllBranches(includeInactive);
      res.json({ success: true, count: branches.length, data: branches });
    } catch (error) {
      next(error);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const branch = await BranchService.getBranchById(req.params.id as string);
      res.json({ success: true, data: branch });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const branch = await BranchService.createBranch(req.body);
      res.status(201).json({ success: true, message: 'Branch created successfully', data: branch });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const branch = await BranchService.updateBranch(req.params.id as string, req.body);
      res.json({ success: true, message: 'Branch updated successfully', data: branch });
    } catch (error) {
      next(error);
    }
  }

  static async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await BranchService.deleteBranch(req.params.id as string);
      res.json({ success: true, message: 'Branch deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
}
