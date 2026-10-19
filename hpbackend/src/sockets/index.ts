// ============================================================
// HungerPoint — Socket.IO Server
// ============================================================

import { Server as HttpServer } from 'http';
import { Server as SocketServer, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { AuthPayload } from '../middleware/auth.middleware';
import { socketOrigins } from '../config/cors';
import { prisma } from '../config/database';

let io: SocketServer;

// The delivery handover PIN is the customer's proof of receipt: it is read only
// through GET /orders/:id by the customer (and admins), never pushed over a
// socket. Order payloads go to kitchen/branch rooms that riders and waiters
// share, so every emitted payload is stripped of it here.
const SECRET_KEYS = new Set(['handoverPin', 'password']);
const stripSecrets = (value: unknown, depth = 0): unknown => {
  if (depth > 6 || value === null || typeof value !== 'object') return value;
  if (value instanceof Date) return value;
  if (Array.isArray(value)) return value.map((v) => stripSecrets(v, depth + 1));
  // Prisma Decimals serialize themselves; leave them intact.
  if (typeof (value as { toJSON?: unknown }).toJSON === 'function' && !(value.constructor === Object)) return value;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
    if (!SECRET_KEYS.has(k)) out[k] = stripSecrets(v, depth + 1);
  }
  return out;
};

const STAFF_SEE_ALL = ['ADMIN'];
const BRANCH_STAFF_ROLES = ['BRANCH_MANAGER', 'BRANCH_STAFF', 'KITCHEN_STAFF', 'WAITER'];

/** Whether this socket's user may follow an order's live updates. */
const canTrackOrder = async (user: AuthPayload | undefined, orderId: string): Promise<boolean> => {
  if (!user || typeof orderId !== 'string' || !orderId) return false;
  if (STAFF_SEE_ALL.includes(user.role)) return true;
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    select: {
      branchId: true,
      customer: { select: { userId: true } },
      delivery: { select: { rider: { select: { userId: true } } } },
    },
  });
  if (!order) return false;
  if (user.role === 'CUSTOMER') return order.customer?.userId === user.userId;
  if (user.role === 'RIDER') return order.delivery?.rider?.userId === user.userId;
  if (BRANCH_STAFF_ROLES.includes(user.role)) return !!user.branchId && order.branchId === user.branchId;
  return false;
};

export const initSocket = (httpServer: HttpServer): SocketServer => {
  const origins = socketOrigins();

  io = new SocketServer(httpServer, {
    cors: {
      origin: origins,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
  });

  // ─── JWT Auth Middleware for Socket ──────────────────────
  io.use((socket: Socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];

    if (!token) {
      // Allow unauthenticated connections (guests can track orders via orderId)
      return next();
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as AuthPayload;
      socket.data.user = decoded;
      next();
    } catch {
      next(); // Allow even if token invalid, just no auth
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = socket.data.user as AuthPayload | undefined;
    console.log(`🔌 Socket connected: ${socket.id} | Role: ${user?.role || 'guest'}`);

    // ─── Join rooms based on role ───────────────────────────
    if (user) {
      // All users join their own room
      socket.join(`user:${user.userId}`);

      // Branch-specific rooms. Riders get only their pool room: the kitchen
      // and branch rooms carry every order of the branch, which is not theirs.
      if (user.branchId) {
        if (user.role === 'RIDER') {
          socket.join(`riders:${user.branchId}`);
        } else {
          socket.join(`branch:${user.branchId}`);
          socket.join(`kitchen:${user.branchId}`);
        }
      }

      // Role-based rooms
      socket.join(`role:${user.role}`);
    }

    // ─── Track an order (customer's own, rider's delivery, branch staff) ──
    socket.on('order:track', async (payload: { orderId?: string } | undefined) => {
      const orderId = payload?.orderId;
      try {
        if (orderId && (await canTrackOrder(user, orderId))) {
          socket.join(`order:${orderId}`);
        }
      } catch (err) {
        console.error('order:track check failed:', err);
      }
    });

    // ─── Rider: location update ─────────────────────────────
    socket.on('rider:location', ({ latitude, longitude, orderId }: {
      latitude: number;
      longitude: number;
      orderId?: string;
    }) => {
      if (!user || user.role !== 'RIDER') return;

      const locationPayload = { riderId: user.userId, latitude, longitude };

      // The customer no longer sees the rider on a map — only an ETA countdown —
      // so the position goes to admins only.
      // Broadcast to admin room
      io.to('role:ADMIN').emit('rider.location_updated', locationPayload);
    });

    // ─── Disconnect ─────────────────────────────────────────
    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: ${socket.id}`);
    });
  });

  return io;
};

// ─── Emit Helpers ─────────────────────────────────────────────
// Every payload passes through stripSecrets (see above).

/** Emit to a specific user */
export const emitToUser = (userId: string, event: string, data: unknown): void => {
  io?.to(`user:${userId}`).emit(event, stripSecrets(data));
};

/** Emit to all users tracking an order */
export const emitToOrder = (orderId: string, event: string, data: unknown): void => {
  io?.to(`order:${orderId}`).emit(event, stripSecrets(data));
};

/** Emit to all kitchen/branch staff at a branch */
export const emitToKitchen = (branchId: string, event: string, data: unknown): void => {
  io?.to(`kitchen:${branchId}`).emit(event, stripSecrets(data));
};

/** Emit to all members of a branch */
export const emitToBranch = (branchId: string, event: string, data: unknown): void => {
  io?.to(`branch:${branchId}`).emit(event, stripSecrets(data));
};

/** Emit to all admins */
export const emitToAdmins = (event: string, data: unknown): void => {
  io?.to('role:ADMIN').emit(event, stripSecrets(data));
};

/** Emit to the riders of one branch (the "available orders" pool) */
export const emitToBranchRiders = (branchId: string, event: string, data: unknown): void => {
  io?.to(`riders:${branchId}`).emit(event, stripSecrets(data));
};

/** Emit to all riders */
export const emitToRiders = (event: string, data: unknown): void => {
  io?.to('role:RIDER').emit(event, stripSecrets(data));
};

// ─── Socket Event Constants ───────────────────────────────────
export const SOCKET_EVENTS = {
  ORDER_CREATED:          'order.created',
  ORDER_CONFIRMED:        'order.confirmed',
  ORDER_ACCEPTED:         'order.accepted',
  ORDER_PREPARING:        'order.preparing',
  ORDER_READY:            'order.ready',
  ORDER_ASSIGNED:         'order.assigned',
  ORDER_PICKED_UP:        'order.picked_up',
  ORDER_OUT_FOR_DELIVERY: 'order.out_for_delivery',
  ORDER_DELIVERED:        'order.delivered',
  ORDER_COMPLETED:        'order.completed',
  ORDER_CANCELLED:        'order.cancelled',
  RIDER_LOCATION_UPDATED: 'rider.location_updated',
  RIDER_ASSIGNMENT:       'rider.assignment_created',
  RIDER_POOL_UPDATED:     'rider.pool_updated',
  ORDER_ETA_UPDATED:      'order.eta_updated',
  WAITER_ORDER_READY:     'waiter.order_ready',
  DELIVERY_PIN_LOCKED:    'delivery.pin_locked',
  INVENTORY_LOW_STOCK:    'inventory.low_stock',
} as const;

export { io };
