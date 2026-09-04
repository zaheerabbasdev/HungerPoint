// ============================================================
// HungerPoint — Rider Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { RiderService } from './rider.service';
import { RiderStatus } from '@prisma/client';

export class RiderController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const { branchId, status } = req.query;
      const riders = await RiderService.getAllRiders({
        branchId: branchId as string,
        status: status as RiderStatus,
      });
      res.json({ success: true, count: riders.length, data: riders });
    } catch (error) {
      next(error);
    }
  }

  static async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { status } = req.body;
      const riderId = req.params.id as string || (req as any).user?.riderId;
      const rider = await RiderService.updateStatus(riderId, status);
      res.json({ success: true, message: `Rider status updated to ${status}`, data: rider });
    } catch (error) {
      next(error);
    }
  }

  static async updateLocation(req: Request, res: Response, next: NextFunction) {
    try {
      const { latitude, longitude, heading, speed } = req.body;
      const riderId = req.params.id as string || (req as any).user?.riderId;
      const location = await RiderService.updateLocation(riderId, Number(latitude), Number(longitude), heading, speed);
      res.json({ success: true, message: 'Location updated', data: location });
    } catch (error) {
      next(error);
    }
  }

  static async assignOrder(req: Request, res: Response, next: NextFunction) {
    try {
      const { orderId, riderId } = req.body;
      const delivery = await RiderService.assignRiderToOrder(orderId, riderId);
      res.json({ success: true, message: 'Rider assigned to order', data: delivery });
    } catch (error) {
      next(error);
    }
  }
}
