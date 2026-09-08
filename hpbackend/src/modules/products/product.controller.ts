// ============================================================
// HungerPoint — Product Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ProductService } from './product.service';

export class ProductController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const { categoryId, search, branchId, includeInactive } = req.query;
      const products = await ProductService.getAllProducts({
        categoryId: categoryId as string,
        search: search as string,
        branchId: branchId as string,
        includeInactive: includeInactive === 'true',
      });
      res.json({ success: true, count: products.length, data: products });
    } catch (error) {
      next(error);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const product = await ProductService.getProductById(req.params.id as string);
      res.json({ success: true, data: product });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const product = await ProductService.createProduct(req.body);
      res.status(201).json({ success: true, message: 'Product created successfully', data: product });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const product = await ProductService.updateProduct(req.params.id as string, req.body);
      res.json({ success: true, message: 'Product updated successfully', data: product });
    } catch (error) {
      next(error);
    }
  }

  static async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await ProductService.deleteProduct(req.params.id as string);
      res.json({ success: true, message: 'Product deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  static async addVariant(req: Request, res: Response, next: NextFunction) {
    try {
      const variant = await ProductService.addVariant(req.params.id as string, req.body);
      res.status(201).json({ success: true, message: 'Variant added successfully', data: variant });
    } catch (error) {
      next(error);
    }
  }

  static async updateVariant(req: Request, res: Response, next: NextFunction) {
    try {
      const variant = await ProductService.updateVariant(req.params.variantId as string, req.body);
      res.json({ success: true, message: 'Variant updated successfully', data: variant });
    } catch (error) {
      next(error);
    }
  }

  static async deleteVariant(req: Request, res: Response, next: NextFunction) {
    try {
      await ProductService.deleteVariant(req.params.variantId as string);
      res.json({ success: true, message: 'Variant deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  // ─── ADDONS ──────────────────────────────────────────────────

  static async getAllAddons(req: Request, res: Response, next: NextFunction) {
    try {
      const addons = await ProductService.getAllAddons();
      res.json({ success: true, count: addons.length, data: addons });
    } catch (error) {
      next(error);
    }
  }

  static async createAddon(req: Request, res: Response, next: NextFunction) {
    try {
      const addon = await ProductService.createAddon(req.body);
      res.status(201).json({ success: true, message: 'Add-on created successfully', data: addon });
    } catch (error) {
      next(error);
    }
  }

  static async deleteAddon(req: Request, res: Response, next: NextFunction) {
    try {
      await ProductService.deleteAddon(req.params.id as string);
      res.json({ success: true, message: 'Add-on deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
}
