// ============================================================
// HungerPoint Web App — Socket.IO Client
// ============================================================

import { io, Socket } from 'socket.io-client';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1';
const SOCKET_URL = API_BASE.replace(/\/api\/v1\/?$/, '');

let socket: Socket | null = null;

/** Returns a singleton, authenticated Socket.IO client connected to the backend. */
export function getSocket(): Socket {
  if (socket) return socket;

  const token = typeof window !== 'undefined' ? localStorage.getItem('hp_access_token') : null;

  socket = io(SOCKET_URL, {
    auth: token ? { token } : {},
    transports: ['websocket', 'polling'],
    autoConnect: true,
  });

  return socket;
}

let kitchenSocket: Socket | null = null;

/** Separate socket authenticated with the kitchen session token only. */
export function getKitchenSocket(): Socket {
  if (kitchenSocket) return kitchenSocket;

  const token = typeof window !== 'undefined' ? localStorage.getItem('hp_kitchen_access_token') : null;

  kitchenSocket = io(SOCKET_URL, {
    auth: token ? { token } : {},
    transports: ['websocket', 'polling'],
    autoConnect: true,
  });

  return kitchenSocket;
}

export function resetKitchenSocket(): void {
  kitchenSocket?.disconnect();
  kitchenSocket = null;
}
