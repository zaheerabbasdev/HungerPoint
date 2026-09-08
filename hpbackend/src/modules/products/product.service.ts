// ============================================================
// HungerPoint — Product Service
// ============================================================

import { prisma } from '../../config/database';

export class ProductService {
  static async getAllProducts(query: { categoryId?: string; search?: string; branchId?: string; includeInactive?: boolean }) {
    const { categoryId, search, branchId, includeInactive } = query;

    const where: any = {};

    if (!includeInactive) {
      where.isActive = true;
    }

    if (categoryId) {
      where.categoryId = categoryId;
    }

    if (search) {
      where.OR = [
        { name: { contains: search } },
        { description: { contains: search } },
      ];
    }

    const products = await prisma.product.findMany({
      where,
      include: {
        category: { select: { id: true, name: true } },
        variants: { where: { isActive: true }, orderBy: { sortOrder: 'asc' } },
        addons: { include: { addon: true } },
        branchProducts: branchId ? { where: { branchId } } : true,
      },
      orderBy: { sortOrder: 'asc' },
    });

    return products;
  }

  static async getProductById(id: string) {
    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        category: true,
        variants: { orderBy: { sortOrder: 'asc' } },
        addons: { include: { addon: true } },
        branchProducts: { include: { branch: true } },
        reviews: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { customer: { include: { user: { select: { name: true } } } } },
        },
      },
    });

    if (!product) {
      const error: any = new Error('Product not found');
      error.statusCode = 404;
      throw error;
    }

    return product;
  }

  static async createProduct(data: {
    categoryId: string;
    name: string;
    description?: string;
    image?: string;
    basePrice: number;
    sortOrder?: number;
    variants?: { name: string; price: number; isDefault?: boolean }[];
    addonIds?: string[];
  }) {
    const { variants, addonIds, ...productData } = data;

    return prisma.product.create({
      data: {
        ...productData,
        variants: variants && variants.length > 0 ? {
          create: variants.map((v, idx) => ({ ...v, sortOrder: idx })),
        } : undefined,
        addons: addonIds && addonIds.length > 0 ? {
          create: addonIds.map((addonId) => ({ addonId })),
        } : undefined,
      },
      include: {
        category: true,
        variants: true,
        addons: { include: { addon: true } },
      },
    });
  }

  static async updateProduct(id: string, data: any) {
    await this.getProductById(id);
    const { variants, addons, addonIds, ...updateData } = data;

    if (addonIds && Array.isArray(addonIds)) {
      await prisma.productAddon.deleteMany({ where: { productId: id } });
      if (addonIds.length > 0) {
        await prisma.productAddon.createMany({
          data: addonIds.map((addonId: string) => ({ productId: id, addonId })),
        });
      }
    }

    return prisma.product.update({
      where: { id },
      data: updateData,
      include: { category: true, variants: true, addons: { include: { addon: true } } },
    });
  }

  static async deleteProduct(id: string) {
    await this.getProductById(id);
    try {
      return await prisma.product.delete({ where: { id } });
    } catch (e) {
      // If referenced in existing orders or carts, soft delete
      return await prisma.product.update({
        where: { id },
        data: { isActive: false },
      });
    }
  }

  static async addVariant(productId: string, data: { name: string; price: number; isDefault?: boolean }) {
    await this.getProductById(productId);
    return prisma.productVariant.create({
      data: { productId, ...data },
    });
  }

  static async updateVariant(variantId: string, data: { name?: string; price?: number; isActive?: boolean; isDefault?: boolean }) {
    return prisma.productVariant.update({
      where: { id: variantId },
      data,
    });
  }

  static async deleteVariant(variantId: string) {
    return prisma.productVariant.delete({ where: { id: variantId } });
  }

  // ─── ADDONS MANAGEMENT ───────────────────────────────────────

  static async getAllAddons() {
    return prisma.addon.findMany({
      orderBy: { name: 'asc' },
    });
  }

  static async createAddon(data: { name: string; price: number }) {
    return prisma.addon.create({
      data,
    });
  }

  static async deleteAddon(id: string) {
    try {
      return await prisma.addon.delete({ where: { id } });
    } catch (e) {
      return await prisma.addon.update({
        where: { id },
        data: { isActive: false },
      });
    }
  }
}
