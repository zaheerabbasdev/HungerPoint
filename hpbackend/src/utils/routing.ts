// ============================================================
// HungerPoint — Road-based travel time
//
// Asks routing services how long the ride takes by real roads. Providers are tried in
// the order listed in ROUTING_PROVIDER (comma separated), e.g. "tpl,osrm". If none answers,
// it falls back to the straight-line estimate in ./eta so an order is never blocked by a
// map problem.
//
//   ROUTING_PROVIDER=osrm              (default) free road routing, no key
//   ROUTING_PROVIDER=none              straight-line estimate only
//   ROUTING_OSRM_URL=...               point at your own OSRM server
//   ROUTING_DAILY_LIMIT_<NAME>=500     stop calling that provider after N calls a day (cost cap
//                                      for paid services, e.g. ROUTING_DAILY_LIMIT_TPL)
//
// To add a provider (e.g. TPL Maps once its API docs are available): write a function with
// the Provider signature and register it in PROVIDERS below. Nothing else changes.
// ============================================================

import { travelMinutes as estimateMinutes } from './eta';

type Point = { latitude?: unknown; longitude?: unknown } | null | undefined;
type LatLon = { lat: number; lon: number };
/** Returns ride minutes by road (no buffer applied) or throws. */
type Provider = (from: LatLon, to: LatLon, signal: AbortSignal) => Promise<number>;

// The free public server can take several seconds, so callers never wait on it for a user action.
const REQUEST_TIMEOUT_MS = 12_000;
// After a failure, skip that provider for a minute instead of timing out on every order.
const BREAKER_COOLDOWN_MS = 60_000;
const CACHE_TTL_MS = 10 * 60_000;
const MIN_TRAVEL_MINUTES = 5;
// Routes are the road time for a car; real rides add parking, stairs and traffic.
const TRAFFIC_BUFFER = 1.2;

const cache = new Map<string, { minutes: number; at: number }>();
const breakerUntil = new Map<string, number>();
const usage = { day: '', calls: new Map<string, number>() };

const coords = (p: Point): LatLon | null => {
  const lat = Number(p?.latitude);
  const lon = Number(p?.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lon) || (lat === 0 && lon === 0)) return null;
  return { lat, lon };
};

// ~110 m precision: nearby points share a cached answer, which also spares the routing server.
const key = (a: LatLon, b: LatLon) => [a.lat, a.lon, b.lat, b.lon].map((n) => n.toFixed(3)).join(',');

// Per-day call counter, so a paid provider's spend can be capped and watched.
const today = () => new Date().toISOString().slice(0, 10);
const rollDay = () => {
  if (usage.day !== today()) {
    usage.day = today();
    usage.calls.clear();
  }
};
const callsToday = (name: string): number => {
  rollDay();
  return usage.calls.get(name) ?? 0;
};
const countCall = (name: string) => usage.calls.set(name, callsToday(name) + 1);
const limitFor = (name: string): number => Number(process.env[`ROUTING_DAILY_LIMIT_${name.toUpperCase()}`]) || 0;

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

// Register new providers here, e.g. `tpl: tplMaps`.
const PROVIDERS: Record<string, Provider> = { osrm };

const configuredProviders = (): string[] =>
  (process.env.ROUTING_PROVIDER || 'osrm')
    .split(',')
    .map((n) => n.trim().toLowerCase())
    .filter((n) => PROVIDERS[n]);

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
    if (!a || !b || typeof fetch !== 'function') return estimateMinutes(from, to, fallback);

    const k = key(a, b);
    const hit = cache.get(k);
    if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.minutes;

    for (const name of configuredProviders()) {
      if (Date.now() < (breakerUntil.get(name) ?? 0)) continue;
      const limit = limitFor(name);
      if (limit && callsToday(name) >= limit) continue;

      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
      try {
        countCall(name);
        const raw = await PROVIDERS[name](a, b, controller.signal);
        const minutes = Math.max(MIN_TRAVEL_MINUTES, Math.ceil(raw * TRAFFIC_BUFFER));
        cache.set(k, { minutes, at: Date.now() });
        return minutes;
      } catch (err) {
        breakerUntil.set(name, Date.now() + BREAKER_COOLDOWN_MS);
        console.warn(`[routing] ${name} unavailable for a minute, trying next:`, (err as Error).message);
      } finally {
        clearTimeout(timer);
      }
    }
    return estimateMinutes(from, to, fallback);
  },

  /** Calls made today per provider (for logs / a future admin screen). */
  usageToday(): Record<string, number> {
    rollDay();
    return Object.fromEntries(usage.calls);
  },
};
