// ============================================================
// HungerPoint Web App — API Client
// ============================================================

export const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1';
export const SERVER_ORIGIN = API_BASE.replace(/\/api\/v1\/?$/, '');

/**
 * Resolves local upload paths, dev machine URLs, and relative image paths
 * to the live backend server origin so images always load in production.
 */
export function resolveImageUrl(url?: string | null): string {
  if (!url || !url.trim()) return '';
  const cleaned = url.trim().replace(/\\/g, '/');
  if (cleaned.startsWith('/uploads/') || cleaned.startsWith('uploads/')) {
    const p = cleaned.startsWith('/') ? cleaned : `/${cleaned}`;
    return `${SERVER_ORIGIN}${p}`;
  }
  if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/i.test(cleaned)) {
    return cleaned.replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/i, SERVER_ORIGIN);
  }
  return cleaned;
}

/**
 * Brand app icon path that works whether hosted at root (/) or in a subfolder (/hungerpoint/).
 */
export const APP_ICON_URL = `${import.meta.env.BASE_URL.replace(/\/$/, '')}/icon.png`;

// Each console keeps its own browser session so the kitchen login is fully
// independent of the admin login (signing into one never signs into the other).
export interface SessionKeys {
  access: string;
  refresh: string;
  user: string;
  expiredEvent: string;
}
export const ADMIN_SESSION: SessionKeys = {
  access: 'hp_access_token',
  refresh: 'hp_refresh_token',
  user: 'hp_user',
  expiredEvent: 'hp_auth_expired',
};
export const KITCHEN_SESSION: SessionKeys = {
  access: 'hp_kitchen_access_token',
  refresh: 'hp_kitchen_refresh_token',
  user: 'hp_kitchen_user',
  expiredEvent: 'hp_kitchen_auth_expired',
};

let isRefreshing = false;
let refreshSubscribers: ((token: string) => void)[] = [];

function onRefreshed(token: string) {
  refreshSubscribers.forEach((cb) => cb(token));
  refreshSubscribers = [];
}

async function tryRefreshToken(session: SessionKeys): Promise<string | null> {
  if (typeof window === 'undefined') return null;
  const refreshToken = localStorage.getItem(session.refresh);
  if (!refreshToken) return null;

  try {
    const res = await fetch(`${API_BASE}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
    const data = await res.json();
    if (res.ok && data.success && data.data?.accessToken) {
      localStorage.setItem(session.access, data.data.accessToken);
      return data.data.accessToken;
    }
  } catch (e) {
    console.error('Failed to refresh token:', e);
  }
  return null;
}

// Pictures are shrunk in the browser before upload: a phone photo of 4–8 MB
// becomes ~200–500 KB. Large uploads were refused on the live server (host
// request limits and MySQL's max_allowed_packet) while working locally.
const MAX_IMAGE_SIDE = 1600;
const IMAGE_QUALITY = 0.85;

async function shrinkImage(file: File): Promise<File> {
  // GIFs may be animated; tiny files aren't worth re-encoding.
  if (file.type === 'image/gif' || file.size < 300 * 1024) return file;
  try {
    const bitmap = await createImageBitmap(file);
    const scale = Math.min(1, MAX_IMAGE_SIDE / Math.max(bitmap.width, bitmap.height));
    const canvas = document.createElement('canvas');
    canvas.width = Math.round(bitmap.width * scale);
    canvas.height = Math.round(bitmap.height * scale);
    const ctx = canvas.getContext('2d');
    if (!ctx) return file;
    // PNGs can be transparent: keep that with WebP; photos go to JPEG.
    const type = file.type === 'image/png' ? 'image/webp' : 'image/jpeg';
    if (type === 'image/jpeg') {
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }
    ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
    bitmap.close();
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, type, IMAGE_QUALITY));
    if (!blob || blob.size >= file.size) return file;
    const ext = type === 'image/webp' ? '.webp' : '.jpg';
    return new File([blob], file.name.replace(/\.[^.]+$/, '') + ext, { type });
  } catch {
    return file; // Browser can't decode it here — let the server decide.
  }
}

/**
 * Uploads a picture to the backend (stored in the database, so it survives
 * redeploys) and returns its public URL. Throws an Error with a readable
 * message when the upload fails — never falls back to embedding the picture.
 */
export async function uploadImage(file: File, session: SessionKeys = ADMIN_SESSION): Promise<string> {
  const image = await shrinkImage(file);

  const send = (token: string | null) => {
    const formData = new FormData();
    formData.append('image', image);
    return fetch(`${API_BASE}/upload`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData,
    });
  };

  let res: Response;
  try {
    res = await send(localStorage.getItem(session.access));
    if (res.status === 401) {
      const fresh = await tryRefreshToken(session);
      if (!fresh) {
        window.dispatchEvent(new Event(session.expiredEvent));
        throw new Error('Your session has expired. Please sign in again.');
      }
      res = await send(fresh);
    }
  } catch (err) {
    if (err instanceof Error && err.message.startsWith('Your session')) throw err;
    // A proxy refusing the request (e.g. too large) sends no CORS headers, so
    // the browser reports it only as a network failure.
    throw new Error('Could not reach the server to upload the picture. Check your connection, or try a smaller picture.', { cause: err });
  }

  const data = await res.json().catch(() => null);
  if (res.ok && data?.success && data.data?.url) return data.data.url as string;
  if (res.status === 413) throw new Error(data?.message || 'This picture is too large for the server. Please use a smaller picture.');
  throw new Error(data?.message || `Picture upload failed (error ${res.status}).`);
}

export async function fetchApi(
  endpoint: string,
  options: RequestInit = {},
  session: SessionKeys = ADMIN_SESSION,
): Promise<any> {
  const token = typeof window !== 'undefined' ? localStorage.getItem(session.access) : null;

  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {}),
  };

  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  // Handle 401 Unauthorized
  if (response.status === 401) {
    // Avoid infinite loop for auth routes
    if (endpoint.startsWith('/auth/login') || endpoint.startsWith('/auth/refresh')) {
      const errData = await response.json().catch(() => ({}));
      throw new Error(errData.message || 'Authentication failed');
    }

    if (!isRefreshing) {
      isRefreshing = true;
      const newToken = await tryRefreshToken(session);
      isRefreshing = false;

      if (newToken) {
        onRefreshed(newToken);
        // Retry original request with new token
        return fetchApi(endpoint, options, session);
      } else {
        // Clear expired session and notify UI
        if (typeof window !== 'undefined') {
          localStorage.removeItem(session.access);
          localStorage.removeItem(session.refresh);
          localStorage.removeItem(session.user);
          window.dispatchEvent(new Event(session.expiredEvent));
        }
        throw new Error('Your session has expired. Please log in again.');
      }
    } else {
      // Queue request until token is refreshed
      return new Promise((resolve) => {
        refreshSubscribers.push(() => {
          resolve(fetchApi(endpoint, options, session));
        });
      });
    }
  }

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.message || 'Something went wrong');
  }

  return data;
}
