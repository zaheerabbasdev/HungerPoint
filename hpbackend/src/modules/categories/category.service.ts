// ============================================================
// HungerPoint — Category Service
// ============================================================

import { prisma } from '../../config/database';

export class CategoryService {
  static async getAllCategories(includeInactive = false) {
    return prisma.category.findMany({
      where: includeInactive ? {} : { isActive: true },
      include: {
        products: {
          where: { isActive: true },
          select: { id: true, name: true, basePrice: true, image: true },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  static async getCategoryById(id: string) {
    const category = await prisma.category.findUnique({
      where: { id },
      include: {
        products: {
          include: {
            variants: true,
            addons: { include: { addon: true } },
          },
        },
      },
    });

    if (!category) {
      const error: any = new Error('Category not found');
      error.statusCode = 404;
      throw error;
    }

    return category;
  }

  static async createCategory(data: { name: string; description?: string; image?: string; sortOrder?: number }) {
    const existing = await prisma.category.findUnique({ where: { name: data.name } });
    if (existing) {
      const error: any = new Error('Category with this name already exists');
      error.statusCode = 400;
      throw error;
    }

    return prisma.category.create({ data });
  }

  static async updateCategory(id: string, data: { name?: string; description?: string; image?: string; sortOrder?: number; isActive?: boolean }) {
    await this.getCategoryById(id);
    return prisma.category.update({ where: { id }, data });
  }

  static async deleteCategory(id: string) {
    await this.getCategoryById(id);
    try {
      return await prisma.category.delete({ where: { id } });
    } catch (e) {
      // If products exist linked to this category, soft delete by marking inactive
      return await prisma.category.update({
        where: { id },
        data: { isActive: false },
      });
    }
  }
}
