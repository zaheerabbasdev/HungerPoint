// ============================================================
// HungerPoint Web App — API Client
// ============================================================

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api/v1';

let isRefreshing = false;
let refreshSubscribers: ((token: string) => void)[] = [];

function onRefreshed(token: string) {
  refreshSubscribers.forEach((cb) => cb(token));
  refreshSubscribers = [];
}

async function tryRefreshToken(): Promise<string | null> {
  if (typeof window === 'undefined') return null;
  const refreshToken = localStorage.getItem('hp_refresh_token');
  if (!refreshToken) return null;

  try {
    const res = await fetch(`${API_BASE}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
    const data = await res.json();
    if (res.ok && data.success && data.data?.accessToken) {
      localStorage.setItem('hp_access_token', data.data.accessToken);
      return data.data.accessToken;
    }
  } catch (e) {
    console.error('Failed to refresh token:', e);
  }
  return null;
}

export async function fetchApi(endpoint: string, options: RequestInit = {}): Promise<any> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('hp_access_token') : null;

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
      const newToken = await tryRefreshToken();
      isRefreshing = false;

      if (newToken) {
        onRefreshed(newToken);
        // Retry original request with new token
        return fetchApi(endpoint, options);
      } else {
        // Clear expired session and notify UI
        if (typeof window !== 'undefined') {
          localStorage.removeItem('hp_access_token');
          localStorage.removeItem('hp_refresh_token');
          localStorage.removeItem('hp_user');
          window.dispatchEvent(new Event('hp_auth_expired'));
        }
        throw new Error('Your session has expired. Please log in again.');
      }
    } else {
      // Queue request until token is refreshed
      return new Promise((resolve) => {
        refreshSubscribers.push(() => {
          resolve(fetchApi(endpoint, options));
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
