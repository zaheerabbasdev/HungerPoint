// ============================================================
// HungerPoint — Allowed browser origins (CORS + Socket.IO)
// ============================================================

// The production web app's addresses. Always allowed, so the site keeps
// working even if the CORS_ORIGIN secret on the host is missing or stale.
const PRODUCTION_WEB_ORIGINS = [
  'https://hungerpoint.eaglesoft.org',
  'https://eaglesoft.org',
];

const parse = (value?: string) =>
  (value || '')
    .split(',')
    .map((o) => o.trim().replace(/\/$/, ''))
    .filter(Boolean);

const unique = (list: string[]) => [...new Set(list)];

/** Origins allowed to call the REST API: the CORS_ORIGIN secret plus the production web app. */
export const apiOrigins = (): string[] =>
  unique([...parse(process.env.CORS_ORIGIN || 'http://localhost:3000'), ...PRODUCTION_WEB_ORIGINS]);

/** Origins allowed to open a Socket.IO connection. */
export const socketOrigins = (): string[] =>
  unique([...parse(process.env.SOCKET_CORS_ORIGIN || 'http://localhost:3000'), ...PRODUCTION_WEB_ORIGINS]);
