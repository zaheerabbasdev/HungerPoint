// ============================================================
// HungerPoint Web App — Navbar Header
// ============================================================

'use client';

import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { useBranch } from '../context/BranchContext';

export function Navbar({ onOpenAuth }: { onOpenAuth: () => void }) {
  const { user, logout } = useAuth();
  const { items, setIsCartOpen } = useCart();
  const { branches, selectedBranchId, setSelectedBranchId } = useBranch();
  const [orderType, setOrderType] = useState<'DELIVERY' | 'PICKUP'>('DELIVERY');

  const totalItemsCount = items.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <header className="sticky top-0 z-40 w-full backdrop-blur-md bg-stone-900/90 border-b border-amber-500/20 text-stone-100 shadow-xl">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between gap-4">
        
        {/* Brand Logo */}
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-amber-500 via-orange-600 to-red-600 flex items-center justify-center shadow-lg shadow-orange-500/30">
            <span className="text-2xl font-black text-white tracking-tighter">HP</span>
          </div>
          <div>
            <h1 className="text-2xl font-extrabold tracking-tight bg-gradient-to-r from-amber-400 via-orange-400 to-red-500 bg-clip-text text-transparent">
              HungerPoint
            </h1>
            <p className="text-[10px] text-stone-400 uppercase tracking-widest font-semibold">Gourmet Food & Delivery</p>
          </div>
        </div>

        {/* Branch & Order Type Selection */}
        <div className="hidden md:flex items-center gap-3 bg-stone-800/80 p-1.5 rounded-2xl border border-stone-700/60 shadow-inner">
          <div className="flex items-center gap-1 bg-stone-900 px-3 py-1.5 rounded-xl text-xs text-amber-400 font-medium">
            <span>📍</span>
            <select
              value={selectedBranchId ?? ''}
              onChange={(e) => setSelectedBranchId(e.target.value)}
              disabled={branches.length === 0}
              className="bg-transparent outline-none cursor-pointer font-semibold text-stone-200"
            >
              {branches.length === 0 && (
                <option value="" className="bg-stone-900">Loading branches...</option>
              )}
              {branches.map((b) => (
                <option key={b.id} value={b.id} className="bg-stone-900">
                  {b.name}{b.city ? `, ${b.city}` : ''}
                </option>
              ))}
            </select>
          </div>

          <div className="flex text-xs font-semibold p-0.5 bg-stone-900 rounded-xl">
            <button
              onClick={() => setOrderType('DELIVERY')}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                orderType === 'DELIVERY'
                  ? 'bg-gradient-to-r from-amber-500 to-orange-600 text-white shadow-md'
                  : 'text-stone-400 hover:text-stone-200'
              }`}
            >
              🛵 Delivery
            </button>
            <button
              onClick={() => setOrderType('PICKUP')}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                orderType === 'PICKUP'
                  ? 'bg-gradient-to-r from-amber-500 to-orange-600 text-white shadow-md'
                  : 'text-stone-400 hover:text-stone-200'
              }`}
            >
              🛍️ Takeaway
            </button>
          </div>
        </div>

        {/* User Profile & Cart Drawer Launcher */}
        <div className="flex items-center gap-3">
          {user ? (
            <div className="flex items-center gap-3 bg-stone-800/80 px-3 py-1.5 rounded-xl border border-stone-700/60">
              <div className="text-right">
                <p className="text-xs font-bold text-stone-100">{user.name}</p>
                <p className="text-[10px] text-amber-400 font-semibold uppercase">{user.role}</p>
              </div>
              <button
                onClick={logout}
                title="Logout"
                className="text-stone-400 hover:text-red-400 text-xs px-2 py-1 bg-stone-900 hover:bg-red-950/40 rounded-lg border border-stone-700 transition-colors"
              >
                Logout
              </button>
            </div>
          ) : (
            <button
              onClick={onOpenAuth}
              className="px-4 py-2 text-xs font-bold bg-stone-800 hover:bg-stone-700 text-amber-400 rounded-xl border border-amber-500/30 transition-all shadow-sm"
            >
              Sign In
            </button>
          )}

          {/* Cart Button */}
          <button
            onClick={() => setIsCartOpen(true)}
            className="relative px-4 py-2.5 bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white font-extrabold text-xs rounded-xl shadow-lg shadow-orange-500/25 flex items-center gap-2 transition-all transform active:scale-95"
          >
            <span>🛒</span>
            <span>Cart</span>
            {totalItemsCount > 0 && (
              <span className="ml-1 px-2 py-0.5 bg-white text-orange-600 rounded-full text-[11px] font-black shadow-sm">
                {totalItemsCount}
              </span>
            )}
          </button>
        </div>

      </div>
    </header>
  );
}
