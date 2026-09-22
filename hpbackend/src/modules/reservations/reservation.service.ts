// ============================================================
// HungerPoint — Table Reservation Service
// ============================================================

import { prisma } from '../../config/database';
import { ReservationStatus } from '@prisma/client';
import { AppError } from '../../middleware/error.middleware';

export class ReservationService {
  static async getReservations(query: { branchId?: string; status?: ReservationStatus; tableId?: string }) {
    return prisma.tableReservation.findMany({
      where: {
        ...(query.branchId ? { branchId: query.branchId } : {}),
        ...(query.status ? { status: query.status } : {}),
        ...(query.tableId ? { tableId: query.tableId } : {}),
      },
      orderBy: { reservedFor: 'asc' },
      include: {
        table: true,
        waiter: { select: { id: true, name: true } },
      },
    });
  }

  static async getReservationById(id: string) {
    const reservation = await prisma.tableReservation.findUnique({
      where: { id },
      include: { table: true, waiter: { select: { id: true, name: true } } },
    });
    if (!reservation) throw new AppError('Reservation not found', 404);
    return reservation;
  }

  static async createReservation(data: {
    tableId: string;
    branchId: string;
    waiterId?: string;
    guestName: string;
    guestPhone: string;
    partySize?: number;
    reservedFor: Date | string;
    notes?: string;
  }) {
    const table = await prisma.restaurantTable.findUnique({ where: { id: data.tableId } });
    if (!table) throw new AppError('Table not found', 404);
    if (table.status !== 'AVAILABLE') {
      throw new AppError(`Table ${table.number} isn't available to reserve right now (currently ${table.status}).`, 400);
    }

    const [reservation] = await prisma.$transaction([
      prisma.tableReservation.create({
        data: {
          tableId: data.tableId,
          branchId: data.branchId,
          waiterId: data.waiterId,
          guestName: data.guestName,
          guestPhone: data.guestPhone,
          partySize: data.partySize ?? 2,
          reservedFor: new Date(data.reservedFor),
          notes: data.notes,
        },
        include: { table: true, waiter: { select: { id: true, name: true } } },
      }),
      prisma.restaurantTable.update({ where: { id: data.tableId }, data: { status: 'RESERVED' } }),
    ]);

    return reservation;
  }

  /** Guests for this reservation have arrived — free the table up for ordering. */
  static async seatReservation(id: string) {
    const reservation = await this.getReservationById(id);
    if (reservation.status !== 'UPCOMING') {
      throw new AppError(`This reservation is already ${reservation.status.toLowerCase()}.`, 400);
    }

    const [updated] = await prisma.$transaction([
      prisma.tableReservation.update({ where: { id }, data: { status: 'SEATED' }, include: { table: true, waiter: { select: { id: true, name: true } } } }),
      prisma.restaurantTable.update({ where: { id: reservation.tableId }, data: { status: 'OCCUPIED' } }),
    ]);

    return updated;
  }

  static async cancelReservation(id: string, noShow = false) {
    const reservation = await this.getReservationById(id);
    if (reservation.status !== 'UPCOMING') {
      throw new AppError(`This reservation is already ${reservation.status.toLowerCase()}.`, 400);
    }

    const [updated] = await prisma.$transaction([
      prisma.tableReservation.update({
        where: { id },
        data: { status: noShow ? 'NO_SHOW' : 'CANCELLED' },
        include: { table: true, waiter: { select: { id: true, name: true } } },
      }),
      prisma.restaurantTable.update({ where: { id: reservation.tableId }, data: { status: 'AVAILABLE' } }),
    ]);

    return updated;
  }
}
