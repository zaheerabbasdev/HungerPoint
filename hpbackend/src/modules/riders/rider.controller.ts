// ============================================================
// HungerPoint — Rider Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { RiderService } from './rider.service';
import { RiderStatus } from '@prisma/client';

export class RiderController {
  static async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const rider = await RiderService.getRiderProfileByUserId(userId);
      res.json({ success: true, data: rider });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const branchId = user.role === 'BRANCH_MANAGER' ? user.branchId : req.body.branchId;
      const rider = await RiderService.createRider({ ...req.body, branchId });
      res.status(201).json({ success: true, message: 'Rider created successfully', data: rider });
    } catch (error) {
      next(error);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const data = { ...req.body };
      if (user.role === 'BRANCH_MANAGER') delete data.branchId;
      const rider = await RiderService.updateRider(req.params.id as string, data);
      res.json({ success: true, message: 'Rider updated successfully', data: rider });
    } catch (error) {
      next(error);
    }
  }

  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const { status } = req.query;
      const branchId = user.role === 'BRANCH_MANAGER' ? user.branchId : (req.query.branchId as string | undefined);
      const riders = await RiderService.getAllRiders({
        branchId,
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
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const rider = await RiderService.getRiderByUserId(userId);
      const updated = await RiderService.updateStatus(rider.id, status);
      res.json({ success: true, message: `Rider status updated to ${status}`, data: updated });
    } catch (error) {
      next(error);
    }
  }

  static async updateLocation(req: Request, res: Response, next: NextFunction) {
    try {
      const { latitude, longitude, heading, speed } = req.body;
      const userId = (req as any).user?.userId || (req as any).user?.id;
      const rider = await RiderService.getRiderByUserId(userId);
      const location = await RiderService.updateLocation(rider.id, Number(latitude), Number(longitude), heading, speed);
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
