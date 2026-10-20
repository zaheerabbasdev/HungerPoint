// ============================================================
// HungerPoint Web App — Cart Context
// ============================================================
// The cart lives in this browser (like the mobile app's CartService). Each line
// carries its size, flavour, add-ons and drink, so what the customer picked is
// exactly what is sent when the order is placed.

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { lineKey, toNumber, type OrderLine } from '../lib/menu';

export type CartItem = OrderLine;

interface CartContextType {
  items: CartItem[];
  addItem: (item: Omit<CartItem, 'id'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  subtotal: number;
  itemCount: number;
  isCartOpen: boolean;
  setIsCartOpen: (open: boolean) => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);
const STORAGE_KEY = 'hp_cart';

// Older versions stored lines without add-ons/flavour/drink: fill the gaps so they still load.
function normalise(raw: any[]): CartItem[] {
  return raw
    .filter((r) => r && r.productId)
    .map((r) => ({
      id: String(r.id ?? `${r.productId}-${Date.now()}`),
      productId: r.productId,
      name: r.name ?? 'Item',
      image: r.image,
      variantId: r.variantId,
      variantName: r.variantName,
      flavour: r.flavour,
      addons: Array.isArray(r.addons) ? r.addons : [],
      drinkId: r.drinkId,
      drinkName: r.drinkName,
      drinkPrice: r.drinkPrice,
      notes: r.notes,
      unitPrice: toNumber(r.unitPrice ?? r.price),
      quantity: Math.max(1, toNumber(r.quantity) || 1),
    }));
}

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>(() => {
    try {
      return normalise(JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]'));
    } catch {
      return [];
    }
  });
  const [isCartOpen, setIsCartOpen] = useState(false);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch {
      /* storage full / private mode: the cart still works for this visit */
    }
  }, [items]);

  const addItem = useCallback((newItem: Omit<CartItem, 'id'>) => {
    setItems((prev) => {
      const key = lineKey(newItem);
      const idx = prev.findIndex((l) => lineKey(l) === key);
      if (idx > -1) {
        const next = [...prev];
        next[idx] = { ...next[idx], quantity: Math.min(50, next[idx].quantity + newItem.quantity) };
        return next;
      }
      return [...prev, { ...newItem, id: `${newItem.productId}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}` }];
    });
    setIsCartOpen(true);
  }, []);

  const removeItem = useCallback((id: string) => setItems((prev) => prev.filter((l) => l.id !== id)), []);

  const updateQuantity = useCallback((id: string, quantity: number) => {
    setItems((prev) =>
      quantity <= 0 ? prev.filter((l) => l.id !== id) : prev.map((l) => (l.id === id ? { ...l, quantity: Math.min(50, quantity) } : l)),
    );
  }, []);

  const clearCart = useCallback(() => setItems([]), []);

  const subtotal = items.reduce((sum, l) => sum + l.unitPrice * l.quantity, 0);
  const itemCount = items.reduce((sum, l) => sum + l.quantity, 0);

  return (
    <CartContext.Provider value={{ items, addItem, removeItem, updateQuantity, clearCart, subtotal, itemCount, isCartOpen, setIsCartOpen }}>
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
