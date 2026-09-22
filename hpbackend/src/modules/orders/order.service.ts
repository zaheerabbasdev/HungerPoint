// ============================================================
// HungerPoint — Order Service
// ============================================================

import { prisma } from '../../config/database';
import { OrderStatus, PaymentMethod, OrderType, OrderSource, LoyaltyTransactionType } from '@prisma/client';
import { emitToKitchen, emitToAdmins, emitToOrder, SOCKET_EVENTS } from '../../sockets';
import { LoyaltyService } from '../loyalty/loyalty.service';

export class OrderService {
  static async createOrder(data: {
    customerId?: string | null;
    branchId: string;
    addressId?: string;
    tableId?: string;
    waiterId?: string;
    type?: OrderType;
    source?: OrderSource;
    paymentMethod?: PaymentMethod;
    notes?: string;
    items: {
      productId: string;
      variantId?: string;
      quantity: number;
      notes?: string;
      addonIds?: string[];
    }[];
  }) {
    const orderNumber = `HP-${Date.now().toString().slice(-6)}-${Math.floor(1000 + Math.random() * 9000)}`;

    let subtotal = 0;
    const orderItemsData: any[] = [];

    for (const item of data.items) {
      const product = await prisma.product.findUnique({ where: { id: item.productId } });
      if (!product) {
        throw new Error(`Product not found: ${item.productId}`);
      }

      let variantPrice = 0;
      if (item.variantId) {
        const variant = await prisma.productVariant.findUnique({ where: { id: item.variantId } });
        if (variant) {
          variantPrice = Number(variant.price);
        }
      }

      let addonsPrice = 0;
      const addonCreates: { addonId: string; addonName: string; price: number }[] = [];
      if (item.addonIds && item.addonIds.length > 0) {
        const addonRecords = await prisma.addon.findMany({ where: { id: { in: item.addonIds } } });
        for (const a of addonRecords) {
          const price = Number(a.price);
          addonsPrice += price;
          addonCreates.push({ addonId: a.id, addonName: a.name, price });
        }
      }

      const unitPrice = Number(product.basePrice);
      const itemTotal = (unitPrice + variantPrice + addonsPrice) * item.quantity;
      subtotal += itemTotal;

      orderItemsData.push({
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
        unitPrice,
        variantPrice,
        totalPrice: itemTotal,
        notes: item.notes,
        addons: addonCreates.length > 0 ? { create: addonCreates } : undefined,
      });
    }

    // Dine-in and pickup orders never carry a delivery fee.
    const deliveryFee = data.type === OrderType.PICKUP || data.type === OrderType.DINE_IN ? 0 : 50;
    const tax = subtotal * 0.05; // 5% tax
    const total = subtotal + deliveryFee + tax;

    const order = await prisma.order.create({
      data: {
        orderNumber,
        customerId: data.customerId || undefined,
        branchId: data.branchId,
        addressId: data.addressId,
        tableId: data.tableId,
        waiterId: data.waiterId,
        type: data.type || OrderType.DELIVERY,
        source: data.source || OrderSource.MOBILE_APP,
        paymentMethod: data.paymentMethod || PaymentMethod.CASH_ON_DELIVERY,
        // A waiter standing at the table has already vetted a dine-in order,
        // so it skips the PENDING/needs-confirmation step and goes straight
        // to the kitchen queue (which only shows CONFIRMED+ orders).
        status: data.type === OrderType.DINE_IN ? OrderStatus.CONFIRMED : OrderStatus.PENDING,
        confirmedAt: data.type === OrderType.DINE_IN ? new Date() : undefined,
        subtotal,
        deliveryFee,
        tax,
        total,
        notes: data.notes,
        statusHistory: {
          create: {
            status: data.type === OrderType.DINE_IN ? OrderStatus.CONFIRMED : OrderStatus.PENDING,
            notes: data.type === OrderType.DINE_IN ? 'Dine-in order sent to kitchen' : 'Order created',
          },
        },
        items: {
          create: orderItemsData,
        },
      },
      include: {
        items: { include: { product: true, variant: true, addons: true } },
        statusHistory: true,
        branch: true,
        table: true,
        waiter: { select: { id: true, name: true } },
      },
    });

    // A dine-in order occupies its table until it's completed/cancelled.
    if (order.tableId) {
      await prisma.restaurantTable.update({
        where: { id: order.tableId },
        data: { status: 'OCCUPIED' },
      });
    }

    // Broadcast Real-Time Socket.IO Events
    if (order.branchId) {
      emitToKitchen(order.branchId, SOCKET_EVENTS.ORDER_CREATED, order);
      emitToKitchen(order.branchId, 'kitchen.queue_updated', order);
    }
    emitToAdmins(SOCKET_EVENTS.ORDER_CREATED, order);

    return order;
  }

  static async getOrders(query: { customerId?: string; branchId?: string; waiterId?: string; tableId?: string; status?: OrderStatus; type?: OrderType; page?: number; limit?: number }) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.customerId) where.customerId = query.customerId;
    if (query.branchId) where.branchId = query.branchId;
    if (query.waiterId) where.waiterId = query.waiterId;
    if (query.tableId) where.tableId = query.tableId;
    if (query.status) where.status = query.status;
    if (query.type) where.type = query.type;

    const [total, orders] = await Promise.all([
      prisma.order.count({ where }),
      prisma.order.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          items: { include: { product: true, variant: true, addons: true } },
          customer: { include: { user: { select: { name: true, phone: true } } } },
          branch: { select: { name: true } },
          table: true,
          waiter: { select: { id: true, name: true } },
          delivery: { include: { rider: { include: { user: { select: { name: true, phone: true } } } } } },
        },
      }),
    ]);

    return { total, page, limit, totalPages: Math.ceil(total / limit), orders };
  }

  static async getOrderById(id: string) {
    const order = await prisma.order.findUnique({
      where: { id },
      include: {
        items: { include: { product: true, variant: true, addons: true } },
        customer: { include: { user: { select: { name: true, email: true, phone: true } } } },
        branch: true,
        address: true,
        table: true,
        waiter: { select: { id: true, name: true } },
        statusHistory: { orderBy: { createdAt: 'asc' } },
        payment: true,
        delivery: { include: { rider: { include: { user: { select: { name: true, phone: true } } } } } },
      },
    });

    if (!order) {
      const error: any = new Error('Order not found');
      error.statusCode = 404;
      throw error;
    }

    return order;
  }

  static async updateOrderStatus(id: string, status: OrderStatus, notes?: string, changedById?: string) {
    await this.getOrderById(id);

    const updateData: any = { status };
    const now = new Date();

    if (status === OrderStatus.CONFIRMED) updateData.confirmedAt = now;
    if (status === OrderStatus.PREPARING) updateData.acceptedAt = now;
    if (status === OrderStatus.READY) updateData.readyAt = now;
    if (status === OrderStatus.OUT_FOR_DELIVERY) updateData.pickedUpAt = now;
    if (status === OrderStatus.DELIVERED) updateData.deliveredAt = now;
    if (status === OrderStatus.CANCELLED) updateData.cancelledAt = now;

    const updated = await prisma.order.update({
      where: { id },
      data: {
        ...updateData,
        statusHistory: {
          create: {
            status,
            notes: notes || `Status changed to ${status}`,
            changedById,
          },
        },
      },
      include: {
        statusHistory: true,
        items: true,
      },
    });

    emitToOrder(id, `order.${status.toLowerCase()}`, updated);
    emitToAdmins(`order.${status.toLowerCase()}`, updated);

    // A dine-in table frees up once its order is done — served & paid
    // (COMPLETED) or called off (CANCELLED) — either way, seats free up.
    if (updated.tableId && (status === OrderStatus.COMPLETED || status === OrderStatus.CANCELLED)) {
      await prisma.restaurantTable.update({
        where: { id: updated.tableId },
        data: { status: 'AVAILABLE' },
      }).catch((err) => console.error('Failed to free table:', err));
    }

    // Award loyalty points on a successful delivery or a completed dine-in
    // visit (1 point per PKR 100 spent). Loyalty is purely additive here
    // and never blocks the order flow.
    if ((status === OrderStatus.DELIVERED || status === OrderStatus.COMPLETED) && updated.customerId) {
      const points = Math.floor(Number(updated.total) / 100);
      if (points > 0) {
        LoyaltyService.adjustPoints(
          updated.customerId,
          points,
          LoyaltyTransactionType.EARNED,
          `Earned from order ${updated.orderNumber}`,
          updated.id
        ).catch((err) => console.error('Failed to award loyalty points:', err));
      }
    }

    return updated;
  }
}
