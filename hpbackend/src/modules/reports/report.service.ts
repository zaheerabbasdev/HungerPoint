// ============================================================
// HungerPoint — Report & Analytics Service
// ============================================================

import { prisma } from '../../config/database';

export interface DateRange {
  from?: Date;
  to?: Date;
}

const createdAtFilter = (range: DateRange) => {
  if (!range.from && !range.to) return undefined;
  return {
    ...(range.from ? { gte: range.from } : {}),
    ...(range.to ? { lte: range.to } : {}),
  };
};

const orderWhere = (branchId: string | undefined, range: DateRange) => {
  const where: any = {};
  if (branchId) where.branchId = branchId;
  const createdAt = createdAtFilter(range);
  if (createdAt) where.createdAt = createdAt;
  return where;
};

export class ReportService {
  static async getDashboardOverview(branchId: string | undefined, range: DateRange = {}) {
    const where = orderWhere(branchId, range);

    const [totalOrders, totalRevenueResult, pendingOrders, activeRiders, totalProducts, totalCustomers] = await Promise.all([
      prisma.order.count({ where }),
      prisma.order.aggregate({
        where: { ...where, status: 'DELIVERED' },
        _sum: { total: true },
        _count: { _all: true },
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

    const totalRevenue = Number(totalRevenueResult._sum.total || 0);
    const deliveredCount = totalRevenueResult._count._all;

    return {
      totalOrders,
      totalRevenue,
      deliveredOrders: deliveredCount,
      averageOrderValue: deliveredCount > 0 ? totalRevenue / deliveredCount : 0,
      pendingOrders,
      activeRiders,
      totalProducts,
      totalCustomers,
      recentOrders,
    };
  }

  static async getOrdersByStatus(branchId: string | undefined, range: DateRange = {}) {
    const grouped = await prisma.order.groupBy({
      by: ['status'],
      where: orderWhere(branchId, range),
      _count: { _all: true },
    });

    return grouped.map((g) => ({ status: g.status, count: g._count._all }));
  }

  static async getTopProducts(branchId: string | undefined, range: DateRange = {}, limit = 10) {
    const orderFilter = orderWhere(branchId, range);
    const where: any = Object.keys(orderFilter).length > 0 ? { order: orderFilter } : {};

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

  static async getOrdersBySource(branchId: string | undefined, range: DateRange = {}) {
    const grouped = await prisma.order.groupBy({
      by: ['source'],
      where: orderWhere(branchId, range),
      _count: { _all: true },
    });

    return grouped.map((g) => ({ source: g.source, count: g._count._all }));
  }

  static async getOrdersPage(branchId: string | undefined, range: DateRange, page: number, pageSize: number) {
    const where = orderWhere(branchId, range);

    const [total, items] = await Promise.all([
      prisma.order.count({ where }),
      prisma.order.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          orderNumber: true,
          status: true,
          type: true,
          source: true,
          paymentMethod: true,
          total: true,
          createdAt: true,
          branch: { select: { name: true } },
          customer: { select: { user: { select: { name: true, phone: true } } } },
        },
      }),
    ]);

    return {
      items,
      total,
      page,
      pageSize,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    };
  }
}
