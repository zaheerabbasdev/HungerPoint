// ============================================================
// HungerPoint — Report & Analytics Service
// ============================================================

import { prisma } from '../../config/database';

export class ReportService {
  static async getDashboardOverview(branchId?: string) {
    const where: any = {};
    if (branchId) where.branchId = branchId;

    const [totalOrders, totalRevenueResult, pendingOrders, activeRiders, totalProducts, totalCustomers] = await Promise.all([
      prisma.order.count({ where }),
      prisma.order.aggregate({
        where: { ...where, status: 'DELIVERED' },
        _sum: { total: true },
      }),
      prisma.order.count({ where: { ...where, status: { in: ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY'] } } }),
      prisma.rider.count({ where: { status: 'ONLINE' } }),
      prisma.product.count({ where: { isActive: true } }),
      prisma.customer.count(),
    ]);

    const recentOrders = await prisma.order.findMany({
      where,
      take: 5,
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { include: { user: { select: { name: true, phone: true } } } },
      },
    });

    return {
      totalOrders,
      totalRevenue: Number(totalRevenueResult._sum.total || 0),
      pendingOrders,
      activeRiders,
      totalProducts,
      totalCustomers,
      recentOrders,
    };
  }

  static async getOrdersByStatus(branchId?: string) {
    const where: any = {};
    if (branchId) where.branchId = branchId;

    const grouped = await prisma.order.groupBy({
      by: ['status'],
      where,
      _count: { _all: true },
    });

    return grouped.map((g) => ({ status: g.status, count: g._count._all }));
  }

  static async getTopProducts(branchId?: string, limit = 10) {
    const where: any = {};
    if (branchId) where.order = { branchId };

    const grouped = await prisma.orderItem.groupBy({
      by: ['productId'],
      where,
      _sum: { quantity: true, totalPrice: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: limit,
    });

    const products = await prisma.product.findMany({
      where: { id: { in: grouped.map((g) => g.productId) } },
      select: { id: true, name: true, image: true },
    });
    const productMap = new Map(products.map((p) => [p.id, p]));

    return grouped.map((g) => ({
      product: productMap.get(g.productId) || null,
      quantitySold: g._sum.quantity || 0,
      revenue: Number(g._sum.totalPrice || 0),
    }));
  }

  static async getOrdersBySource(branchId?: string) {
    const where: any = {};
    if (branchId) where.branchId = branchId;

    const grouped = await prisma.order.groupBy({
      by: ['source'],
      where,
      _count: { _all: true },
    });

    return grouped.map((g) => ({ source: g.source, count: g._count._all }));
  }
}
