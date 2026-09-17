// ============================================================
// HungerPoint — User (Staff Account) Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { UserService } from './user.service';

export class UserController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const users = await UserService.getStaffUsers();
      res.json({ success: true, count: users.length, data: users });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await UserService.createStaffUser(req.body);
      res.status(201).json({ success: true, message: 'Staff account created', data: user });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await UserService.updateStaffUser(req.params.id as string, req.body);
      res.json({ success: true, message: 'Staff account updated', data: user });
    } catch (error) {
      next(error);
    }
  }
}
