// ============================================================
// HungerPoint — Loyalty Service
// ============================================================

import { prisma } from '../../config/database';
import { LoyaltyTransactionType } from '@prisma/client';

export class LoyaltyService {
  static async getOrCreateAccount(customerId: string) {
    let account = await prisma.loyaltyAccount.findUnique({ where: { customerId } });
    if (!account) {
      account = await prisma.loyaltyAccount.create({ data: { customerId } });
    }
    return account;
  }

  static async getAllAccounts() {
    return prisma.loyaltyAccount.findMany({
      orderBy: { points: 'desc' },
      include: {
        customer: { include: { user: { select: { name: true, phone: true } } } },
      },
    });
  }

  static async getAccountByCustomerId(customerId: string) {
    const account = await this.getOrCreateAccount(customerId);
    const transactions = await prisma.loyaltyTransaction.findMany({
      where: { accountId: account.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return { ...account, transactions };
  }

  /** Adjust a customer's points balance (admin action, or earn/redeem from order flow). */
  static async adjustPoints(customerId: string, points: number, type: LoyaltyTransactionType, notes?: string, orderId?: string) {
    const account = await this.getOrCreateAccount(customerId);

    const delta = type === LoyaltyTransactionType.REDEEMED || type === LoyaltyTransactionType.EXPIRED ? -Math.abs(points) : Math.abs(points);

    const updated = await prisma.loyaltyAccount.update({
      where: { id: account.id },
      data: {
        points: { increment: delta },
        lifetime: delta > 0 ? { increment: delta } : undefined,
      },
    });

    await prisma.loyaltyTransaction.create({
      data: {
        accountId: account.id,
        orderId,
        type,
        points: delta,
        notes,
      },
    });

    return updated;
  }
}
