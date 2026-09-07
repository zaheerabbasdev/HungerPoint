// ============================================================
// HungerPoint Backend — Notification Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { NotificationService } from './notification.service';

export class NotificationController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      await NotificationService.seedSampleNotifications();
      const userId = (req as any).user?.id;
      const notifications = await NotificationService.getUserNotifications(userId);
      res.json({ success: true, count: notifications.length, data: notifications });
    } catch (error) {
      next(error);
    }
  }

  static async markRead(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const updated = await NotificationService.markAsRead(id as string);
      res.json({ success: true, data: updated });
    } catch (error) {
      next(error);
    }
  }
}
