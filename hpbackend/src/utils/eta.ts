// ============================================================
// HungerPoint — Delivery time estimates
// ============================================================

const AVERAGE_RIDER_SPEED_KMH = 25;
const MIN_TRAVEL_MINUTES = 5;
// Road distance is longer than the straight line between two points.
const ROAD_FACTOR = 1.3;

const toRad = (deg: number): number => (deg * Math.PI) / 180;

export const distanceKm = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

/** Estimated minutes to ride between two points; falls back to a default when a point is unknown. */
export const travelMinutes = (
  from: { latitude?: unknown; longitude?: unknown } | null | undefined,
  to: { latitude?: unknown; longitude?: unknown } | null | undefined,
  fallback = 15,
): number => {
  const lat1 = Number(from?.latitude), lon1 = Number(from?.longitude);
  const lat2 = Number(to?.latitude), lon2 = Number(to?.longitude);
  if (![lat1, lon1, lat2, lon2].every(Number.isFinite) || (lat1 === 0 && lon1 === 0) || (lat2 === 0 && lon2 === 0)) {
    return fallback;
  }
  const km = distanceKm(lat1, lon1, lat2, lon2) * ROAD_FACTOR;
  return Math.max(MIN_TRAVEL_MINUTES, Math.round((km / AVERAGE_RIDER_SPEED_KMH) * 60));
};
