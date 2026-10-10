// ============================================================
// HungerPoint — Road-based travel time
//
// Asks a routing service how long the ride takes by real roads. If the service
// is unreachable, slow or not configured, it falls back to the straight-line
// estimate in ./eta so an order is never blocked by a map problem.
//
// Provider is chosen by ROUTING_PROVIDER:
//   osrm  (default) free road routing, no key. ROUTING_OSRM_URL can point to your own server.
//   none            skip the service and use the straight-line estimate only.
// To add another provider (e.g. TPL Maps once its API key + docs are available), add a
// function to PROVIDERS below; nothing else in the app changes.
// ============================================================

import { travelMinutes as estimateMinutes } from './eta';

type Point = { latitude?: unknown; longitude?: unknown } | null | undefined;

// The free public server can take several seconds, so callers never wait on it for a user action.
const REQUEST_TIMEOUT_MS = 12_000;
// After a failure, skip the routing server for a minute instead of timing out on every order.
const BREAKER_COOLDOWN_MS = 60_000;
let breakerUntil = 0;
const CACHE_TTL_MS = 10 * 60_000;
const MIN_TRAVEL_MINUTES = 5;
// Routes are the road time for a car; real rides add parking, stairs and traffic.
const TRAFFIC_BUFFER = 1.2;

const cache = new Map<string, { minutes: number; at: number }>();

const coords = (p: Point): { lat: number; lon: number } | null => {
  const lat = Number(p?.latitude);
  const lon = Number(p?.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lon) || (lat === 0 && lon === 0)) return null;
  return { lat, lon };
};

// ~110 m precision: nearby points share a cached answer, which also spares the routing server.
const key = (a: { lat: number; lon: number }, b: { lat: number; lon: number }) =>
  [a.lat, a.lon, b.lat, b.lon].map((n) => n.toFixed(3)).join(',');

type Provider = (from: { lat: number; lon: number }, to: { lat: number; lon: number }, signal: AbortSignal) => Promise<number>;

const osrm: Provider = async (from, to, signal) => {
  const base = (process.env.ROUTING_OSRM_URL || 'https://router.project-osrm.org').replace(/\/+$/, '');
  const url = `${base}/route/v1/driving/${from.lon},${from.lat};${to.lon},${to.lat}?overview=false`;
  const res = await fetch(url, { signal, headers: { 'User-Agent': 'HungerPoint-Backend' } });
  if (!res.ok) throw new Error(`OSRM HTTP ${res.status}`);
  const data: any = await res.json();
  const seconds = data?.routes?.[0]?.duration;
  if (data?.code !== 'Ok' || !Number.isFinite(seconds)) throw new Error('OSRM returned no route');
  return seconds / 60;
};

const PROVIDERS: Record<string, Provider> = { osrm };

export const RoutingService = {
  /** Instant answer (never waits on the network): a recent road time if cached, else the straight-line estimate. */
  estimateNow(from: Point, to: Point, fallback = 15): number {
    const a = coords(from);
    const b = coords(to);
    if (a && b) {
      const hit = cache.get(key(a, b));
      if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.minutes;
    }
    return estimateMinutes(from, to, fallback);
  },

  /** Ride minutes between two points, by road when possible, straight-line estimate otherwise. */
  async travelMinutes(from: Point, to: Point, fallback = 15): Promise<number> {
    const a = coords(from);
    const b = coords(to);
    if (!a || !b) return estimateMinutes(from, to, fallback);

    const name = (process.env.ROUTING_PROVIDER || 'osrm').toLowerCase();
    const provider = PROVIDERS[name];
    if (!provider || typeof fetch !== 'function') return estimateMinutes(from, to, fallback);

    const k = key(a, b);
    const hit = cache.get(k);
    if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.minutes;
    if (Date.now() < breakerUntil) return estimateMinutes(from, to, fallback);

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const raw = await provider(a, b, controller.signal);
      const minutes = Math.max(MIN_TRAVEL_MINUTES, Math.ceil(raw * TRAFFIC_BUFFER));
      cache.set(k, { minutes, at: Date.now() });
      return minutes;
    } catch (err) {
      breakerUntil = Date.now() + BREAKER_COOLDOWN_MS;
      console.warn(`[routing] ${name} unavailable, using straight-line estimate for a minute:`, (err as Error).message);
      return estimateMinutes(from, to, fallback);
    } finally {
      clearTimeout(timer);
    }
  },
};
