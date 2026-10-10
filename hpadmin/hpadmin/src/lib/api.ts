// ============================================================
// HungerPoint Web App — API Client
// ============================================================

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1';

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
