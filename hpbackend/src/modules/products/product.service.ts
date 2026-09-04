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
  }) {
    const { variants, ...productData } = data;

    return prisma.product.create({
      data: {
        ...productData,
        variants: variants && variants.length > 0 ? {
          create: variants.map((v, idx) => ({ ...v, sortOrder: idx })),
        } : undefined,
      },
      include: {
        category: true,
        variants: true,
      },
    });
  }

  static async updateProduct(id: string, data: any) {
    await this.getProductById(id);
    const { variants, addons, ...updateData } = data;

    return prisma.product.update({
      where: { id },
      data: updateData,
      include: { category: true, variants: true },
    });
  }

  static async deleteProduct(id: string) {
    await this.getProductById(id);
    return prisma.product.delete({ where: { id } });
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
}
