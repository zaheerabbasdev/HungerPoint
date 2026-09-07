// ============================================================
// HungerPoint Backend — Notification Service
// ============================================================

import { prisma } from '../../config/database';
import { NotificationType } from '@prisma/client';

export class NotificationService {
  static async getUserNotifications(userId?: string) {
    if (userId) {
      const userNotifs = await prisma.notification.findMany({
        where: { OR: [{ userId }, { userId: null }] },
        orderBy: { createdAt: 'desc' },
        take: 30,
      });
      if (userNotifs.length > 0) return userNotifs;
    }

    // Return system & promotion notifications
    return prisma.notification.findMany({
      where: { userId: null },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }

  static async seedSampleNotifications() {
    const count = await prisma.notification.count();
    if (count === 0) {
      await prisma.notification.createMany({
        data: [
          {
            type: NotificationType.PROMOTION,
            title: 'Flat 50% OFF on your first order! 🎉',
            body: 'Use promo code WELCOME50 at checkout to get 50% off on all items.',
            isRead: false,
          },
          {
            type: NotificationType.ORDER_STATUS,
            title: 'Welcome to HungerPoint! 🍕',
            body: 'Freshly baked pizzas, crispy gourmet burgers and fast delivery in Islamabad.',
            isRead: true,
          },
          {
            type: NotificationType.SYSTEM,
            title: 'New Branch in F-7 Markaz! 📍',
            body: 'Our new branch in F-7 Markaz is now open for Dine In, Delivery, and Pick-Up.',
            isRead: true,
          },
        ],
      });
    }
  }

  static async markAsRead(id: string) {
    return prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }
}
