// ============================================================
// HungerPoint — Delivery Controller (rider-facing)
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { DeliveryService } from './delivery.service';
import { RiderService } from '../riders/rider.service';

async function resolveRiderId(req: Request): Promise<string> {
  const userId = (req as any).user?.userId || (req as any).user?.id;
  const rider = await RiderService.getRiderByUserId(userId);
  return rider.id;
}

export class DeliveryController {
  static async getActive(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const delivery = await DeliveryService.getActiveForRider(riderId);
      res.json({ success: true, data: delivery });
    } catch (error) {
      next(error);
    }
  }

  static async getHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const { page, limit } = req.query;
      const result = await DeliveryService.getHistoryForRider(riderId, Number(page) || 1, Number(limit) || 20);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  }

  static async accept(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const delivery = await DeliveryService.accept(req.params.id as string, riderId);
      res.json({ success: true, message: 'Delivery accepted', data: delivery });
    } catch (error) {
      next(error);
    }
  }

  static async pickup(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const delivery = await DeliveryService.markPickedUp(req.params.id as string, riderId);
      res.json({ success: true, message: 'Order marked as picked up', data: delivery });
    } catch (error) {
      next(error);
    }
  }

  static async outForDelivery(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const delivery = await DeliveryService.markOutForDelivery(req.params.id as string, riderId);
      res.json({ success: true, message: 'Delivery started', data: delivery });
    } catch (error) {
      next(error);
    }
  }

  static async delivered(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const delivery = await DeliveryService.markDelivered(req.params.id as string, riderId);
      res.json({ success: true, message: 'Delivery completed', data: delivery });
    } catch (error) {
      next(error);
    }
  }

  static async failed(req: Request, res: Response, next: NextFunction) {
    try {
      const riderId = await resolveRiderId(req);
      const delivery = await DeliveryService.markFailed(req.params.id as string, riderId, req.body?.reason);
      res.json({ success: true, message: 'Delivery marked as failed', data: delivery });
    } catch (error) {
      next(error);
    }
  }
}
