// ============================================================
// HungerPoint — Favorites Service
// ============================================================

import { prisma } from '../../config/database';
import { CustomerService } from '../customers/customer.service';

export class FavoriteService {
  static async getFavorites(userId: string) {
    const customer = await CustomerService.getOrCreateCustomer(userId);
    const favorites = await prisma.favorite.findMany({
      where: { customerId: customer.id },
      orderBy: { createdAt: 'desc' },
      include: {
        product: {
          include: {
            category: { select: { id: true, name: true } },
            variants: true,
            addons: { include: { addon: true } },
          },
        },
      },
    });
    return favorites.map((f) => f.product);
  }

  static async addFavorite(userId: string, productId: string) {
    const customer = await CustomerService.getOrCreateCustomer(userId);
    return prisma.favorite.upsert({
      where: { customerId_productId: { customerId: customer.id, productId } },
      create: { customerId: customer.id, productId },
      update: {},
    });
  }

  static async removeFavorite(userId: string, productId: string) {
    const customer = await CustomerService.getOrCreateCustomer(userId);
    await prisma.favorite.deleteMany({
      where: { customerId: customer.id, productId },
    });
  }
}
