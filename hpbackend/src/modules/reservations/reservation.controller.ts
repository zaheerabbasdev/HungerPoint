// ============================================================
// HungerPoint — Table Reservation Controller
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { ReservationService } from './reservation.service';

export class ReservationController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      let branchId = req.query.branchId as string | undefined;
      if (['BRANCH_MANAGER', 'BRANCH_STAFF', 'WAITER'].includes(user?.role)) {
        branchId = user.branchId || undefined;
      }
      const reservations = await ReservationService.getReservations({
        branchId,
        status: req.query.status as any,
        tableId: req.query.tableId as string,
      });
      res.json({ success: true, count: reservations.length, data: reservations });
    } catch (error) {
      next(error);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const waiterId = user?.role === 'WAITER' ? (user.userId || user.id) : undefined;
      const reservation = await ReservationService.createReservation({ ...req.body, waiterId });
      res.status(201).json({ success: true, message: 'Table reserved', data: reservation });
    } catch (error) {
      next(error);
    }
  }

  static async seat(req: Request, res: Response, next: NextFunction) {
    try {
      const reservation = await ReservationService.seatReservation(req.params.id as string);
      res.json({ success: true, message: 'Guests seated', data: reservation });
    } catch (error) {
      next(error);
    }
  }

  static async cancel(req: Request, res: Response, next: NextFunction) {
    try {
      const noShow = req.body?.noShow === true;
      const reservation = await ReservationService.cancelReservation(req.params.id as string, noShow);
      res.json({ success: true, message: noShow ? 'Marked as no-show' : 'Reservation cancelled', data: reservation });
    } catch (error) {
      next(error);
    }
  }
}
