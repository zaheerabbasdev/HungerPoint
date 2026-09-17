// ============================================================
// HungerPoint — System Settings Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { SettingService } from './setting.service';

export class SettingController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const settings = await SettingService.getAll();
      res.json({ success: true, count: settings.length, data: settings });
    } catch (error) {
      next(error);
    }
  }

  static async upsert(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { value, group } = req.body;
      if (value === undefined) {
        res.status(400).json({ success: false, message: 'value is required' });
        return;
      }
      const setting = await SettingService.upsert(req.params.key as string, String(value), group);
      res.json({ success: true, message: 'Setting updated', data: setting });
    } catch (error) {
      next(error);
    }
  }
}
