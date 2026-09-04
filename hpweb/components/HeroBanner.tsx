// ============================================================
// HungerPoint Web App — Hero Banner Component
// ============================================================

'use client';

import React from 'react';

export function HeroBanner({
  searchQuery,
  setSearchQuery,
}: {
  searchQuery: string;
  setSearchQuery: (q: string) => void;
}) {
  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-stone-900 via-stone-900 to-amber-950/40 border border-amber-500/20 shadow-2xl p-8 sm:p-12 mb-8">
      {/* Background glow effects */}
      <div className="absolute -top-24 -right-24 w-96 h-96 bg-orange-600/20 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-24 -left-24 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="relative z-10 max-w-2xl space-y-6">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-bold uppercase tracking-wider">
          <span>🔥</span>
          <span>Fast Delivery • Fresh Ingredients</span>
        </div>

        <h2 className="text-4xl sm:text-5xl font-black text-stone-100 tracking-tight leading-tight">
          Craving Delicious{' '}
          <span className="bg-gradient-to-r from-amber-400 via-orange-400 to-red-500 bg-clip-text text-transparent">
            Gourmet Food?
          </span>
        </h2>

        <p className="text-stone-300 text-sm sm:text-base leading-relaxed">
          Order handcrafted burgers, wood-fired artisan pizzas, and refreshing shakes delivered piping hot to your doorstep in Islamabad!
        </p>

        {/* Live Search Input */}
        <div className="relative max-w-lg">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search for Zinger, Smash Burger, Pepperoni Pizza..."
            className="w-full bg-stone-950/90 border border-stone-700/80 rounded-2xl pl-12 pr-4 py-4 text-sm text-stone-100 placeholder-stone-500 outline-none focus:border-amber-500 shadow-xl backdrop-blur-md"
          />
          <span className="absolute left-4 top-1/2 -translate-y-1/2 text-xl opacity-60">🔍</span>
        </div>
      </div>
    </div>
  );
}
