// ============================================================
// HungerPoint — Order Service
// ============================================================

import { prisma } from '../../config/database';
import { OrderStatus, PaymentMethod, OrderType, OrderSource } from '@prisma/client';
import { emitToKitchen, emitToAdmins, emitToOrder, SOCKET_EVENTS } from '../../sockets';

export class OrderService {
  static async createOrder(data: {
    customerId: string;
    branchId: string;
    addressId?: string;
    type?: OrderType;
    paymentMethod?: PaymentMethod;
    notes?: string;
    items: {
      productId: string;
      variantId?: string;
      quantity: number;
      notes?: string;
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

      const unitPrice = Number(product.basePrice);
      const itemTotal = (unitPrice + variantPrice) * item.quantity;
      subtotal += itemTotal;

      orderItemsData.push({
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
        unitPrice,
        variantPrice,
        totalPrice: itemTotal,
        notes: item.notes,
      });
    }

    const deliveryFee = data.type === OrderType.PICKUP ? 0 : 50;
    const tax = subtotal * 0.05; // 5% tax
    const total = subtotal + deliveryFee + tax;

    const order = await prisma.order.create({
      data: {
        orderNumber,
        customerId: data.customerId,
        branchId: data.branchId,
        addressId: data.addressId,
        type: data.type || OrderType.DELIVERY,
        paymentMethod: data.paymentMethod || PaymentMethod.CASH_ON_DELIVERY,
        subtotal,
        deliveryFee,
        tax,
        total,
        notes: data.notes,
        statusHistory: {
          create: {
            status: OrderStatus.PENDING,
            notes: 'Order created',
          },
        },
        items: {
          create: orderItemsData,
        },
      },
      include: {
        items: { include: { product: true, variant: true } },
        statusHistory: true,
        branch: true,
      },
    });

    // Broadcast Real-Time Socket.IO Events
    emitToKitchen(order.branchId, SOCKET_EVENTS.ORDER_CREATED, order);
    emitToAdmins(SOCKET_EVENTS.ORDER_CREATED, order);

    return order;
  }

  static async getOrders(query: { customerId?: string; branchId?: string; status?: OrderStatus; page?: number; limit?: number }) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.customerId) where.customerId = query.customerId;
    if (query.branchId) where.branchId = query.branchId;
    if (query.status) where.status = query.status;

    const [total, orders] = await Promise.all([
      prisma.order.count({ where }),
      prisma.order.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          items: { include: { product: true, variant: true } },
          customer: { include: { user: { select: { name: true, phone: true } } } },
          branch: { select: { name: true } },
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

    return updated;
  }
}
