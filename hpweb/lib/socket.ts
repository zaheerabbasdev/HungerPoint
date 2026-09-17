// ============================================================
// HungerPoint Web App — Socket.IO Client
// ============================================================

import { io, Socket } from 'socket.io-client';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api/v1';
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
