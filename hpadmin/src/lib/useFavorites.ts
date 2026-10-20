// ============================================================
// HungerPoint Web App — Favourites (signed-in customers)
// ============================================================

import { useCallback, useEffect, useState } from 'react';
import { fetchApi } from './api';
import { useAuth } from '../context/AuthContext';
import type { MenuProduct } from './menu';

export function useFavorites() {
  const { user } = useAuth();
  const isCustomer = user?.role === 'CUSTOMER';
  const [favorites, setFavorites] = useState<MenuProduct[]>([]);

  const reload = useCallback(async () => {
    if (!isCustomer) return setFavorites([]);
    try {
      const res = await fetchApi('/favorites');
      if (res.success) setFavorites(res.data || []);
    } catch {
      /* hearts simply stay empty */
    }
  }, [isCustomer]);

  useEffect(() => {
    reload();
  }, [reload]);

  const isFavorite = (productId: string) => favorites.some((f) => f.id === productId);

  /** Returns false when the visitor is not a signed-in customer (caller can open sign-in). */
  const toggle = async (product: MenuProduct): Promise<boolean> => {
    if (!isCustomer) return false;
    const was = isFavorite(product.id);
    // Optimistic: the heart flips at once, then the server confirms.
    setFavorites((prev) => (was ? prev.filter((f) => f.id !== product.id) : [product, ...prev]));
    try {
      if (was) await fetchApi(`/favorites/${product.id}`, { method: 'DELETE' });
      else await fetchApi('/favorites', { method: 'POST', body: JSON.stringify({ productId: product.id }) });
    } catch {
      reload();
    }
    return true;
  };

  return { favorites, isFavorite, toggle, reload, isCustomer };
}
