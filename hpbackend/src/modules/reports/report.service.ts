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
        branch: { select: { name: true } },
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
}
