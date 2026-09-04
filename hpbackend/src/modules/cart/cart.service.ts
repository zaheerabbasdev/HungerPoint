// ============================================================
// HungerPoint — Cart Service
// ============================================================

import { prisma } from '../../config/database';

export class CartService {
  static async getCartByCustomerId(customerId: string) {
    let cart = await prisma.cart.findUnique({
      where: { customerId },
      include: {
        items: {
          include: {
            product: { select: { id: true, name: true, image: true, basePrice: true } },
            variant: { select: { id: true, name: true, price: true } },
            addons: true,
          },
        },
      },
    });

    if (!cart) {
      cart = await prisma.cart.create({
        data: { customerId },
        include: {
          items: {
            include: {
              product: { select: { id: true, name: true, image: true, basePrice: true } },
              variant: { select: { id: true, name: true, price: true } },
              addons: true,
            },
          },
        },
      });
    }

    return cart;
  }

  static async addItem(customerId: string, data: { productId: string; variantId?: string; quantity: number; notes?: string }) {
    const cart = await this.getCartByCustomerId(customerId);

    // Check existing item
    const existing = cart.items.find(
      (item) => item.productId === data.productId && item.variantId === (data.variantId || null)
    );

    if (existing) {
      return prisma.cartItem.update({
        where: { id: existing.id },
        data: { quantity: existing.quantity + (data.quantity || 1) },
      });
    }

    return prisma.cartItem.create({
      data: {
        cartId: cart.id,
        productId: data.productId,
        variantId: data.variantId,
        quantity: data.quantity || 1,
        notes: data.notes,
      },
    });
  }

  static async updateItemQuantity(cartItemId: string, quantity: number) {
    if (quantity <= 0) {
      return prisma.cartItem.delete({ where: { id: cartItemId } });
    }
    return prisma.cartItem.update({
      where: { id: cartItemId },
      data: { quantity },
    });
  }

  static async removeItem(cartItemId: string) {
    return prisma.cartItem.delete({ where: { id: cartItemId } });
  }

  static async clearCart(customerId: string) {
    const cart = await prisma.cart.findUnique({ where: { customerId } });
    if (cart) {
      await prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
    }
    return { success: true, message: 'Cart cleared' };
  }
}
