// ============================================================
// HungerPoint Web App — Main Customer Storefront
// ============================================================

'use client';

import React, { useState, useEffect } from 'react';
import { Navbar } from '../components/Navbar';
import { HeroBanner } from '../components/HeroBanner';
import { CartDrawer } from '../components/CartDrawer';
import { AuthModal } from '../components/AuthModal';
import { ProductModal, ProductDetail } from '../components/ProductModal';
import { fetchApi } from '../lib/api';
import { useCart } from '../context/CartContext';

export default function HomePage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedProduct, setSelectedProduct] = useState<ProductDetail | null>(null);

  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const { addItem } = useCart();

  useEffect(() => {
    async function loadData() {
      try {
        const [catRes, prodRes] = await Promise.all([
          fetchApi('/categories'),
          fetchApi('/products'),
        ]);
        if (catRes.success) setCategories(catRes.data);
        if (prodRes.success) setProducts(prodRes.data);
      } catch (err) {
        console.error('Failed to load menu data:', err);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  const filteredProducts = products.filter((p) => {
    const matchesCategory = !selectedCategory || p.categoryId === selectedCategory;
    const matchesSearch =
      !searchQuery ||
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.description?.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 font-sans selection:bg-amber-500 selection:text-white">
      
      {/* Header Navigation */}
      <Navbar onOpenAuth={() => setIsAuthOpen(true)} />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
        {/* Hero Section */}
        <HeroBanner searchQuery={searchQuery} setSearchQuery={setSearchQuery} />

        {/* Categories Pill Navigation */}
        <div className="flex items-center gap-3 overflow-x-auto pb-4 mb-8 scrollbar-none">
          <button
            onClick={() => setSelectedCategory(null)}
            className={`px-5 py-2.5 rounded-2xl text-xs font-bold whitespace-nowrap transition-all ${
              selectedCategory === null
                ? 'bg-gradient-to-r from-amber-500 to-orange-600 text-white shadow-lg shadow-orange-500/20'
                : 'bg-stone-900 border border-stone-800 text-stone-400 hover:text-stone-100 hover:border-stone-700'
            }`}
          >
            🍽️ All Items
          </button>
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat.id)}
              className={`px-5 py-2.5 rounded-2xl text-xs font-bold whitespace-nowrap transition-all ${
                selectedCategory === cat.id
                  ? 'bg-gradient-to-r from-amber-500 to-orange-600 text-white shadow-lg shadow-orange-500/20'
                  : 'bg-stone-900 border border-stone-800 text-stone-400 hover:text-stone-100 hover:border-stone-700'
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>

        {/* Product Grid Header */}
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-extrabold text-stone-100">
            {selectedCategory
              ? categories.find((c) => c.id === selectedCategory)?.name || 'Menu Items'
              : 'Popular Gourmet Menu'}
          </h3>
          <span className="text-xs text-stone-500 font-semibold">{filteredProducts.length} items found</span>
        </div>

        {/* Product Grid */}
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="h-80 rounded-3xl bg-stone-900 animate-pulse" />
            ))}
          </div>
        ) : filteredProducts.length === 0 ? (
          <div className="text-center py-20 bg-stone-900/50 rounded-3xl border border-stone-800/80">
            <span className="text-4xl block mb-3">🔍</span>
            <p className="text-stone-300 font-bold text-base">No items match your search</p>
            <p className="text-xs text-stone-500 mt-1">Try clearing filters or searching for something else!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredProducts.map((product) => (
              <div
                key={product.id}
                className="group bg-stone-900 border border-stone-800/80 rounded-3xl overflow-hidden hover:border-amber-500/50 transition-all duration-300 hover:shadow-2xl hover:shadow-amber-500/10 flex flex-col justify-between"
              >
                <div>
                  {/* Image */}
                  <div className="relative h-48 w-full bg-stone-800 overflow-hidden">
                    {product.image ? (
                      <img
                        src={product.image}
                        alt={product.name}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-stone-600 text-3xl">🍔</div>
                    )}
                    <div className="absolute top-3 right-3 px-3 py-1 bg-black/70 backdrop-blur-md rounded-full text-xs font-black text-amber-400 border border-amber-500/30">
                      PKR {Number(product.basePrice).toFixed(0)}
                    </div>
                  </div>

                  {/* Content */}
                  <div className="p-5">
                    <h4 className="text-base font-black text-stone-100 group-hover:text-amber-400 transition-colors">
                      {product.name}
                    </h4>
                    <p className="text-xs text-stone-400 mt-1.5 line-clamp-2 leading-relaxed">
                      {product.description || 'Prepared fresh with high quality ingredients.'}
                    </p>
                  </div>
                </div>

                {/* Card Action */}
                <div className="p-5 pt-0">
                  <button
                    onClick={() => setSelectedProduct(product)}
                    className="w-full py-3 bg-stone-800 hover:bg-gradient-to-r hover:from-amber-500 hover:to-orange-600 text-stone-200 hover:text-white font-extrabold text-xs rounded-2xl border border-stone-700/60 hover:border-transparent transition-all shadow-sm flex items-center justify-center gap-2"
                  >
                    <span>Customize & Add</span>
                    <span>→</span>
                  </button>
                </div>

              </div>
            ))}
          </div>
        )}

      </main>

      {/* Slide-over Cart Drawer & Modals */}
      <CartDrawer />
      <AuthModal isOpen={isAuthOpen} onClose={() => setIsAuthOpen(false)} />
      <ProductModal product={selectedProduct} onClose={() => setSelectedProduct(null)} />

    </div>
  );
}
