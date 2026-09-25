// ============================================================
// HungerPoint — Prisma Database Client
// ============================================================

import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

// Some hosts (e.g. GoDaddy's Node.js App Manager) inject separate
// DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD instead of a single
// DATABASE_URL — build the URL Prisma actually needs from those pieces
// whenever they're present, before the client below reads it. Always
// prefer them over an existing DATABASE_URL: that secret may only hold a
// placeholder value kept around so `prisma generate` has something to
// parse at build time, not the real connection.
if (process.env.DB_HOST) {
  const user = encodeURIComponent(process.env.DB_USER || '');
  const password = encodeURIComponent(process.env.DB_PASSWORD || '');
  const host = process.env.DB_HOST;
  const port = process.env.DB_PORT || '3306';
  const name = process.env.DB_NAME || '';
  process.env.DATABASE_URL = `mysql://${user}:${password}@${host}:${port}/${name}`;
}

// Prevent multiple instances in development (hot reload)
export const prisma = globalThis.__prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development'
    ? ['query', 'info', 'warn', 'error']
    : ['error'],
});

if (process.env.NODE_ENV !== 'production') {
  globalThis.__prisma = prisma;
}
