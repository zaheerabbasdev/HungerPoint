// ============================================================
// HungerPoint — Favorites Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { FavoriteService } from './favorite.service';

export class FavoriteController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const favorites = await FavoriteService.getFavorites(userId);
      res.json({ success: true, count: favorites.length, data: favorites });
    } catch (error) {
      next(error);
    }
  }

  static async add(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const { productId } = req.body;
      if (!productId) {
        res.status(400).json({ success: false, message: 'productId is required' });
        return;
      }
      await FavoriteService.addFavorite(userId, productId);
      res.status(201).json({ success: true, message: 'Added to favorites' });
    } catch (error) {
      next(error);
    }
  }

  static async remove(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      await FavoriteService.removeFavorite(userId, req.params.productId as string);
      res.json({ success: true, message: 'Removed from favorites' });
    } catch (error) {
      next(error);
    }
  }
}
