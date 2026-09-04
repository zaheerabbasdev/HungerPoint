// ============================================================
// HungerPoint — Socket.IO Server
// ============================================================

import { Server as HttpServer } from 'http';
import { Server as SocketServer, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { AuthPayload } from '../middleware/auth.middleware';

let io: SocketServer;

export const initSocket = (httpServer: HttpServer): SocketServer => {
  const origins = (process.env.SOCKET_CORS_ORIGIN || 'http://localhost:3000').split(',');

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

      // Branch-specific rooms
      if (user.branchId) {
        socket.join(`branch:${user.branchId}`);
        socket.join(`kitchen:${user.branchId}`);
      }

      // Role-based rooms
      socket.join(`role:${user.role}`);
    }

    // ─── Customer: track order ──────────────────────────────
    socket.on('order:track', ({ orderId }: { orderId: string }) => {
      socket.join(`order:${orderId}`);
      console.log(`📦 Socket ${socket.id} tracking order: ${orderId}`);
    });

    // ─── Rider: location update ─────────────────────────────
    socket.on('rider:location', ({ latitude, longitude, orderId }: {
      latitude: number;
      longitude: number;
      orderId?: string;
    }) => {
      if (!user || user.role !== 'RIDER') return;

      const locationPayload = { riderId: user.userId, latitude, longitude };

      // Broadcast to order room if on delivery
      if (orderId) {
        io.to(`order:${orderId}`).emit('rider.location_updated', locationPayload);
      }

      // Broadcast to admin room
      io.to('role:ADMIN').emit('rider.location_updated', locationPayload);
      io.to('role:SUPER_ADMIN').emit('rider.location_updated', locationPayload);
    });

    // ─── Disconnect ─────────────────────────────────────────
    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: ${socket.id}`);
    });
  });

  return io;
};

// ─── Emit Helpers ─────────────────────────────────────────────

/** Emit to a specific user */
export const emitToUser = (userId: string, event: string, data: unknown): void => {
  io?.to(`user:${userId}`).emit(event, data);
};

/** Emit to all users tracking an order */
export const emitToOrder = (orderId: string, event: string, data: unknown): void => {
  io?.to(`order:${orderId}`).emit(event, data);
};

/** Emit to all kitchen/branch staff at a branch */
export const emitToKitchen = (branchId: string, event: string, data: unknown): void => {
  io?.to(`kitchen:${branchId}`).emit(event, data);
};

/** Emit to all members of a branch */
export const emitToBranch = (branchId: string, event: string, data: unknown): void => {
  io?.to(`branch:${branchId}`).emit(event, data);
};

/** Emit to all admins */
export const emitToAdmins = (event: string, data: unknown): void => {
  io?.to('role:ADMIN').to('role:SUPER_ADMIN').emit(event, data);
};

/** Emit to all riders */
export const emitToRiders = (event: string, data: unknown): void => {
  io?.to('role:RIDER').emit(event, data);
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
  INVENTORY_LOW_STOCK:    'inventory.low_stock',
} as const;

export { io };
