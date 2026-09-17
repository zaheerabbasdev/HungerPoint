// ============================================================
// HungerPoint Web App — Cart Context
// ============================================================

'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './AuthContext';
import { fetchApi } from '../lib/api';

export interface CartItem {
  id: string;
  productId: string;
  name: string;
  image?: string;
  price: number;
  quantity: number;
  variantId?: string;
  variantName?: string;
  notes?: string;
}

interface CartContextType {
  items: CartItem[];
  addItem: (item: Omit<CartItem, 'id'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  subtotal: number;
  deliveryFee: number;
  tax: number;
  total: number;
  isCartOpen: boolean;
  setIsCartOpen: (open: boolean) => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

function mapBackendCart(cart: any): CartItem[] {
  return (cart?.items || []).map((it: any) => ({
    id: it.id,
    productId: it.productId,
    name: it.product?.name || 'Item',
    image: it.product?.image || undefined,
    price: Number(it.variant?.price ?? it.product?.basePrice ?? 0),
    quantity: it.quantity,
    variantId: it.variantId || undefined,
    variantName: it.variant?.name || undefined,
    notes: it.notes || undefined,
  }));
}

export function CartProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const [items, setItems] = useState<CartItem[]>([]);
  const [isCartOpen, setIsCartOpen] = useState(false);

  // Guest cart: load from localStorage
  useEffect(() => {
    if (user) return;
    const savedCart = localStorage.getItem('hp_cart');
    if (savedCart) {
      try {
        setItems(JSON.parse(savedCart));
      } catch (e) {
        console.error(e);
      }
    }
  }, [user]);

  // Logged-in cart: the backend is the source of truth
  const loadBackendCart = useCallback(async () => {
    try {
      const res = await fetchApi('/cart');
      if (res.success) setItems(mapBackendCart(res.data));
    } catch (e) {
      console.error('Failed to load cart:', e);
    }
  }, []);

  useEffect(() => {
    if (user) loadBackendCart();
  }, [user, loadBackendCart]);

  const saveGuestCart = (newItems: CartItem[]) => {
    setItems(newItems);
    localStorage.setItem('hp_cart', JSON.stringify(newItems));
  };

  const addItem = async (newItem: Omit<CartItem, 'id'>) => {
    if (user) {
      try {
        await fetchApi('/cart/items', {
          method: 'POST',
          body: JSON.stringify({
            productId: newItem.productId,
            variantId: newItem.variantId,
            quantity: newItem.quantity,
            notes: newItem.notes,
          }),
        });
        await loadBackendCart();
      } catch (e) {
        console.error('Failed to add item to cart:', e);
      }
      setIsCartOpen(true);
      return;
    }

    const existingIndex = items.findIndex(
      (item) => item.productId === newItem.productId && item.variantId === newItem.variantId
    );

    if (existingIndex > -1) {
      const updated = [...items];
      updated[existingIndex].quantity += newItem.quantity;
      saveGuestCart(updated);
    } else {
      const id = `${newItem.productId}-${newItem.variantId || 'base'}-${Date.now()}`;
      saveGuestCart([...items, { ...newItem, id }]);
    }
    setIsCartOpen(true);
  };

  const removeItem = async (id: string) => {
    if (user) {
      try {
        await fetchApi(`/cart/items/${id}`, { method: 'DELETE' });
        await loadBackendCart();
      } catch (e) {
        console.error('Failed to remove cart item:', e);
      }
      return;
    }
    saveGuestCart(items.filter((item) => item.id !== id));
  };

  const updateQuantity = async (id: string, quantity: number) => {
    if (quantity <= 0) {
      await removeItem(id);
      return;
    }

    if (user) {
      try {
        await fetchApi(`/cart/items/${id}`, {
          method: 'PUT',
          body: JSON.stringify({ quantity }),
        });
        await loadBackendCart();
      } catch (e) {
        console.error('Failed to update cart item:', e);
      }
      return;
    }

    saveGuestCart(items.map((item) => (item.id === id ? { ...item, quantity } : item)));
  };

  const clearCart = async () => {
    if (user) {
      try {
        await fetchApi('/cart', { method: 'DELETE' });
      } catch (e) {
        console.error('Failed to clear cart:', e);
      }
      setItems([]);
      return;
    }
    saveGuestCart([]);
  };

  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const deliveryFee = items.length > 0 ? 50 : 0;
  const tax = subtotal * 0.05;
  const total = subtotal + deliveryFee + tax;

  return (
    <CartContext.Provider
      value={{
        items,
        addItem,
        removeItem,
        updateQuantity,
        clearCart,
        subtotal,
        deliveryFee,
        tax,
        total,
        isCartOpen,
        setIsCartOpen,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
}
