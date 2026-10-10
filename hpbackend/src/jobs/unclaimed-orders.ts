// ============================================================
// HungerPoint — Unclaimed order alert
// A delivery order that has been READY for a few minutes with no rider on it
// is flagged to the admins (and that branch's managers) so they can assign one.
// ============================================================

import { OrderStatus, OrderType } from '@prisma/client';
import { prisma } from '../config/database';
import { SettingService } from '../modules/settings/setting.service';
import { emitToAdmins, emitToBranch } from '../sockets';

const CHECK_EVERY_MS = 30_000;
const DEFAULT_ALERT_AFTER_MINUTES = 3;

// Orders already alerted, so each one raises a single alert (cleared once it is claimed).
const alerted = new Set<string>();

export const checkUnclaimedOrders = async (): Promise<void> => {
  const minutes = await SettingService.getNumber('unclaimed_order_alert_minutes', DEFAULT_ALERT_AFTER_MINUTES);
  const cutoff = new Date(Date.now() - minutes * 60_000);

  const stale = await prisma.order.findMany({
    where: { type: OrderType.DELIVERY, status: OrderStatus.READY, delivery: null, readyAt: { lte: cutoff } },
    select: { id: true, orderNumber: true, branchId: true, readyAt: true },
  });

  const stillWaiting = new Set(stale.map((o) => o.id));
  for (const id of alerted) {
    if (!stillWaiting.has(id)) alerted.delete(id);
  }

  for (const order of stale) {
    if (alerted.has(order.id)) continue;
    alerted.add(order.id);
    const payload = {
      orderId: order.id,
      orderNumber: order.orderNumber,
      branchId: order.branchId,
      waitingMinutes: Math.max(1, Math.round((Date.now() - (order.readyAt?.getTime() ?? Date.now())) / 60_000)),
    };
    emitToAdmins('order.unclaimed', payload);
    if (order.branchId) emitToBranch(order.branchId, 'order.unclaimed', payload);
  }
};

export const startUnclaimedOrderWatcher = (): void => {
  const run = () => checkUnclaimedOrders().catch((err) => console.error('Unclaimed-order check failed:', err));
  setInterval(run, CHECK_EVERY_MS).unref();
};
