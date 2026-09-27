// ============================================================
// HungerPoint Backend — Notification Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { NotificationService } from './notification.service';

export class NotificationController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      await NotificationService.seedSampleNotifications();
      const notifications = await NotificationService.getUserNotifications(req.user?.userId);
      res.json({ success: true, count: notifications.length, data: notifications });
    } catch (error) {
      next(error);
    }
  }

  static async markRead(req: Request, res: Response, next: NextFunction) {
    try {
      const updated = await NotificationService.markAsRead(req.params.id as string, req.user!.userId);
      res.json({ success: true, data: updated });
    } catch (error) {
      next(error);
    }
  }

  static async markAllRead(req: Request, res: Response, next: NextFunction) {
    try {
      const count = await NotificationService.markAllAsRead(req.user!.userId);
      res.json({ success: true, data: { updated: count } });
    } catch (error) {
      next(error);
    }
  }
}
