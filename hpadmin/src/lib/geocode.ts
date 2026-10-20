// ============================================================
// HungerPoint Web App — Geocoding (OpenStreetMap Nominatim)
// ============================================================
// Free, no API key. Results are requested in English: without `accept-language`
// Nominatim answers in the local language and Pakistani addresses come back in Urdu.

export interface GeoResult {
  lat: number;
  lng: number;
  displayName: string;
}

const BASE = 'https://nominatim.openstreetmap.org';

export async function searchPlaces(query: string): Promise<GeoResult[]> {
  if (!query.trim()) return [];
  const params = new URLSearchParams({ q: query, format: 'jsonv2', countrycodes: 'pk', limit: '6', 'accept-language': 'en' });
  try {
    const res = await fetch(`${BASE}/search?${params}`);
    if (!res.ok) return [];
    const data = (await res.json()) as any[];
    return data.map((d) => ({ lat: Number(d.lat), lng: Number(d.lon), displayName: String(d.display_name || query) }));
  } catch {
    return [];
  }
}

export async function reversePlace(lat: number, lng: number): Promise<string | null> {
  const params = new URLSearchParams({ lat: String(lat), lon: String(lng), format: 'jsonv2', 'accept-language': 'en' });
  try {
    const res = await fetch(`${BASE}/reverse?${params}`);
    if (!res.ok) return null;
    return ((await res.json()) as any).display_name ?? null;
  } catch {
    return null;
  }
}

/** The browser's current position (asks permission). */
export function currentPosition(): Promise<{ lat: number; lng: number }> {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) return reject(new Error('Location is not available in this browser.'));
    navigator.geolocation.getCurrentPosition(
      (p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
      () => reject(new Error('Could not get your location. Allow location access or search for the address instead.')),
      { enableHighAccuracy: true, timeout: 10000 },
    );
  });
}
