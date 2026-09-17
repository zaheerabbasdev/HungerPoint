// ============================================================
// HungerPoint Web App — Point of Sale (POS)
// ============================================================

'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';
import { useBranch } from '../../context/BranchContext';

const POS_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER', 'BRANCH_STAFF'];

interface Variant {
  id: string;
  name: string;
  price: number | string;
  isDefault?: boolean;
}

interface Product {
  id: string;
  categoryId: string;
  name: string;
  description?: string;
  image?: string;
  basePrice: number | string;
  variants?: Variant[];
}

interface OrderLine {
  key: string;
  productId: string;
  name: string;
  image?: string;
  unitPrice: number;
  variantId?: string;
  variantName?: string;
  quantity: number;
}

export default function PosPage() {
  const router = useRouter();
  const { branches, selectedBranchId, selectedBranch, setSelectedBranchId } = useBranch();

  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [categories, setCategories] = useState<any[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loadingMenu, setLoadingMenu] = useState(true);
  const [activeCategoryId, setActiveCategoryId] = useState<string | null>(null);

  const [variantPickerProduct, setVariantPickerProduct] = useState<Product | null>(null);

  const [lines, setLines] = useState<OrderLine[]>([]);
  const [orderType, setOrderType] = useState<'PICKUP' | 'DELIVERY'>('PICKUP');
  const [notes, setNotes] = useState('');

  const [customerPhone, setCustomerPhone] = useState('');
  const [foundCustomer, setFoundCustomer] = useState<{ customerId: string; name: string; phone: string } | null>(null);
  const [searchingCustomer, setSearchingCustomer] = useState(false);
  const [customerNotFound, setCustomerNotFound] = useState(false);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [lastOrder, setLastOrder] = useState<any | null>(null);
  const [error, setError] = useState<string | null>(null);

  // ─── Auth guard ───────────────────────────────────────────
  useEffect(() => {
    const token = localStorage.getItem('hp_access_token');
    const userStr = localStorage.getItem('hp_user');
    let role: string | null = null;
    if (userStr) {
      try {
        role = JSON.parse(userStr)?.role ?? null;
      } catch {
        role = null;
      }
    }
    if (!token || !role || !POS_ALLOWED_ROLES.includes(role)) {
      router.replace('/admin');
      return;
    }
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  // ─── Menu data ────────────────────────────────────────────
  useEffect(() => {
    if (!authorized) return;
    async function loadMenu() {
      try {
        const [catRes, prodRes] = await Promise.all([fetchApi('/categories'), fetchApi('/products')]);
        if (catRes.success) setCategories(catRes.data);
        if (prodRes.success) setProducts(prodRes.data);
      } catch (err) {
        console.error('Failed to load POS menu:', err);
      } finally {
        setLoadingMenu(false);
      }
    }
    loadMenu();
  }, [authorized]);

  const visibleProducts = useMemo(
    () => products.filter((p) => !activeCategoryId || p.categoryId === activeCategoryId),
    [products, activeCategoryId]
  );

  const subtotal = lines.reduce((sum, l) => sum + l.unitPrice * l.quantity, 0);
  const deliveryFee = orderType === 'DELIVERY' ? 50 : 0;
  const tax = subtotal * 0.05;
  const total = subtotal + deliveryFee + tax;

  // ─── Cart line helpers ────────────────────────────────────
  const addLine = (product: Product, variant?: Variant) => {
    const unitPrice = Number(product.basePrice) + (variant ? Number(variant.price) : 0);
    const key = `${product.id}-${variant?.id || 'base'}`;

    setLines((prev) => {
      const idx = prev.findIndex((l) => l.key === key);
      if (idx > -1) {
        const updated = [...prev];
        updated[idx] = { ...updated[idx], quantity: updated[idx].quantity + 1 };
        return updated;
      }
      return [
        ...prev,
        {
          key,
          productId: product.id,
          name: product.name,
          image: product.image,
          unitPrice,
          variantId: variant?.id,
          variantName: variant?.name,
          quantity: 1,
        },
      ];
    });
  };

  const handleProductTap = (product: Product) => {
    if (product.variants && product.variants.length > 0) {
      setVariantPickerProduct(product);
    } else {
      addLine(product);
    }
  };

  const updateQty = (key: string, qty: number) => {
    setLines((prev) => (qty <= 0 ? prev.filter((l) => l.key !== key) : prev.map((l) => (l.key === key ? { ...l, quantity: qty } : l))));
  };

  const resetOrder = () => {
    setLines([]);
    setNotes('');
    setCustomerPhone('');
    setFoundCustomer(null);
    setCustomerNotFound(false);
    setLastOrder(null);
    setError(null);
  };

  // ─── Customer lookup ──────────────────────────────────────
  const handleSearchCustomer = async () => {
    if (!customerPhone.trim()) return;
    setSearchingCustomer(true);
    setCustomerNotFound(false);
    try {
      const res = await fetchApi(`/customers/search?phone=${encodeURIComponent(customerPhone.trim())}`);
      if (res.success && res.data) {
        setFoundCustomer(res.data);
      } else {
        setFoundCustomer(null);
        setCustomerNotFound(true);
      }
    } catch (err) {
      setFoundCustomer(null);
      setCustomerNotFound(true);
    } finally {
      setSearchingCustomer(false);
    }
  };

  // ─── Checkout ─────────────────────────────────────────────
  const handleCharge = async () => {
    if (lines.length === 0) return;
    if (!selectedBranchId) {
      setError('Select a branch before placing the order.');
      return;
    }
    setIsSubmitting(true);
    setError(null);
    try {
      const res = await fetchApi('/orders', {
        method: 'POST',
        body: JSON.stringify({
          branchId: selectedBranchId,
          type: orderType,
          source: 'POS',
          paymentMethod: 'CASH_ON_DELIVERY',
          customerId: foundCustomer?.customerId,
          notes: notes.trim() || undefined,
          items: lines.map((l) => ({
            productId: l.productId,
            variantId: l.variantId,
            quantity: l.quantity,
          })),
        }),
      });

      if (res.success) {
        setLastOrder(res.data);
        setLines([]);
      } else {
        setError(res.message || 'Failed to place order.');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to place order.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Checking access...</p>
      </div>
    );
  }
  if (!authorized) return null;

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 flex flex-col">
      {/* Header */}
      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 flex items-center justify-between gap-4 sticky top-0 z-30">
        <div>
          <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">
            ← Back to Admin Dashboard
          </Link>
          <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2">
            <span>🧾</span> Point of Sale
          </h1>
        </div>
        <div className="flex items-center gap-2 bg-stone-800/80 px-3 py-1.5 rounded-xl border border-stone-700/60 text-xs">
          <span>📍</span>
          <select
            value={selectedBranchId ?? ''}
            onChange={(e) => setSelectedBranchId(e.target.value)}
            className="bg-transparent outline-none cursor-pointer font-semibold text-stone-200"
          >
            {branches.length === 0 && <option value="">Loading...</option>}
            {branches.map((b) => (
              <option key={b.id} value={b.id} className="bg-stone-900">
                {b.name}
              </option>
            ))}
          </select>
        </div>
      </header>

      <div className="flex-1 grid grid-cols-1 lg:grid-cols-[1fr_380px] overflow-hidden">
        {/* Menu Panel */}
        <div className="overflow-y-auto p-5 space-y-4">
          <div className="flex gap-2 overflow-x-auto pb-1">
            <button
              onClick={() => setActiveCategoryId(null)}
              className={`px-4 py-2 rounded-xl text-xs font-extrabold shrink-0 transition-all ${
                !activeCategoryId ? 'bg-amber-500 text-stone-950' : 'bg-stone-800 text-stone-400 hover:text-stone-200'
              }`}
            >
              All
            </button>
            {categories.map((c) => (
              <button
                key={c.id}
                onClick={() => setActiveCategoryId(c.id)}
                className={`px-4 py-2 rounded-xl text-xs font-extrabold shrink-0 transition-all ${
                  activeCategoryId === c.id ? 'bg-amber-500 text-stone-950' : 'bg-stone-800 text-stone-400 hover:text-stone-200'
                }`}
              >
                {c.name}
              </button>
            ))}
          </div>

          {loadingMenu ? (
            <div className="text-center py-20 text-stone-500 text-sm">Loading menu...</div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3">
              {visibleProducts.map((p) => (
                <button
                  key={p.id}
                  onClick={() => handleProductTap(p)}
                  className="text-left bg-stone-900 border border-stone-800 hover:border-amber-500/50 rounded-2xl overflow-hidden transition-all active:scale-95"
                >
                  <div className="h-24 bg-stone-800">
                    {p.image && <img src={p.image} alt={p.name} className="w-full h-full object-cover" />}
                  </div>
                  <div className="p-2.5">
                    <p className="text-xs font-bold text-stone-100 line-clamp-1">{p.name}</p>
                    <p className="text-xs font-mono text-amber-400 font-black mt-0.5">PKR {Number(p.basePrice)}</p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Order Panel */}
        <div className="border-l border-stone-800 bg-stone-900/40 flex flex-col overflow-hidden">
          {lastOrder ? (
            <div className="flex-1 flex flex-col items-center justify-center text-center p-6 space-y-4">
              <div className="w-16 h-16 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center text-3xl">✓</div>
              <h3 className="text-xl font-black text-emerald-400">Order Placed</h3>
              <p className="text-sm text-stone-300">
                Order <span className="font-mono font-bold text-amber-400">{lastOrder.orderNumber}</span>
              </p>
              <p className="text-lg font-black text-stone-100">PKR {Number(lastOrder.total).toFixed(2)}</p>
              <button
                onClick={resetOrder}
                className="px-6 py-3 bg-gradient-to-r from-amber-500 to-orange-600 font-bold text-white rounded-xl shadow-lg"
              >
                New Order
              </button>
            </div>
          ) : (
            <>
              {/* Customer */}
              <div className="p-4 border-b border-stone-800 space-y-2">
                <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider">Customer</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={customerPhone}
                    onChange={(e) => {
                      setCustomerPhone(e.target.value);
                      setFoundCustomer(null);
                      setCustomerNotFound(false);
                    }}
                    placeholder="Phone number (optional)"
                    className="flex-1 bg-stone-900 border border-stone-800 rounded-xl px-3 py-2 text-xs text-stone-200 outline-none focus:border-amber-500"
                  />
                  <button
                    onClick={handleSearchCustomer}
                    disabled={searchingCustomer || !customerPhone.trim()}
                    className="px-3 py-2 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl disabled:opacity-40"
                  >
                    {searchingCustomer ? '...' : 'Find'}
                  </button>
                </div>
                {foundCustomer ? (
                  <p className="text-xs text-emerald-400 font-semibold">✓ {foundCustomer.name} ({foundCustomer.phone})</p>
                ) : customerNotFound ? (
                  <p className="text-xs text-stone-500">No account found — will place as walk-in.</p>
                ) : (
                  <p className="text-xs text-stone-500">Leave blank for a walk-in customer.</p>
                )}
              </div>

              {/* Order type */}
              <div className="p-4 border-b border-stone-800">
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => setOrderType('PICKUP')}
                    className={`py-2 rounded-xl text-xs font-bold border transition-all ${
                      orderType === 'PICKUP' ? 'border-amber-500 bg-amber-500/10 text-amber-400' : 'border-stone-800 text-stone-400'
                    }`}
                  >
                    🛍️ Pickup
                  </button>
                  <button
                    onClick={() => setOrderType('DELIVERY')}
                    className={`py-2 rounded-xl text-xs font-bold border transition-all ${
                      orderType === 'DELIVERY' ? 'border-amber-500 bg-amber-500/10 text-amber-400' : 'border-stone-800 text-stone-400'
                    }`}
                  >
                    🛵 Delivery
                  </button>
                </div>
              </div>

              {/* Lines */}
              <div className="flex-1 overflow-y-auto p-4 space-y-2">
                {lines.length === 0 ? (
                  <p className="text-center text-xs text-stone-600 py-10">Tap products to add them to the order.</p>
                ) : (
                  lines.map((l) => (
                    <div key={l.key} className="p-2.5 bg-stone-800/60 rounded-xl flex items-center justify-between gap-2">
                      <div className="min-w-0">
                        <p className="text-xs font-bold text-stone-200 truncate">{l.name}</p>
                        {l.variantName && <p className="text-[10px] text-amber-400">{l.variantName}</p>}
                        <p className="text-[10px] text-stone-400">PKR {l.unitPrice} each</p>
                      </div>
                      <div className="flex items-center gap-2 bg-stone-900 px-2 py-1 rounded-lg border border-stone-700/60 shrink-0">
                        <button onClick={() => updateQty(l.key, l.quantity - 1)} className="text-stone-400 hover:text-stone-100 text-xs font-bold px-1">-</button>
                        <span className="text-xs font-bold text-amber-400 w-4 text-center">{l.quantity}</span>
                        <button onClick={() => updateQty(l.key, l.quantity + 1)} className="text-stone-400 hover:text-stone-100 text-xs font-bold px-1">+</button>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Totals + Charge */}
              <div className="p-4 border-t border-stone-800 space-y-3">
                <input
                  type="text"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Order notes (optional)"
                  className="w-full bg-stone-900 border border-stone-800 rounded-xl px-3 py-2 text-xs text-stone-200 outline-none focus:border-amber-500"
                />
                <div className="space-y-1 text-xs text-stone-400">
                  <div className="flex justify-between"><span>Subtotal</span><span>PKR {subtotal.toFixed(2)}</span></div>
                  <div className="flex justify-between"><span>Delivery Fee</span><span>PKR {deliveryFee.toFixed(2)}</span></div>
                  <div className="flex justify-between"><span>Tax (5%)</span><span>PKR {tax.toFixed(2)}</span></div>
                  <div className="flex justify-between text-sm font-black text-stone-100 pt-1 border-t border-stone-800">
                    <span>Total</span><span className="text-amber-400">PKR {total.toFixed(2)}</span>
                  </div>
                </div>
                {error && <p className="text-xs text-red-400">{error}</p>}
                <button
                  onClick={handleCharge}
                  disabled={isSubmitting || lines.length === 0}
                  className="w-full py-3 bg-gradient-to-r from-amber-500 via-orange-600 to-red-600 text-white font-extrabold text-sm rounded-xl shadow-lg disabled:opacity-50"
                >
                  {isSubmitting ? 'Placing Order...' : `Charge — Cash (PKR ${total.toFixed(2)})`}
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Variant Picker */}
      {variantPickerProduct && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-4">
            <h3 className="text-base font-black text-stone-100">{variantPickerProduct.name}</h3>
            <div className="space-y-2">
              {variantPickerProduct.variants!.map((v) => (
                <button
                  key={v.id}
                  onClick={() => {
                    addLine(variantPickerProduct, v);
                    setVariantPickerProduct(null);
                  }}
                  className="w-full p-3 rounded-xl text-xs font-bold border border-stone-800 hover:border-amber-500/60 bg-stone-800/40 text-stone-200 flex justify-between items-center"
                >
                  <span>{v.name}</span>
                  <span className="text-amber-400 font-mono">PKR {Number(variantPickerProduct.basePrice) + Number(v.price)}</span>
                </button>
              ))}
            </div>
            <button
              onClick={() => setVariantPickerProduct(null)}
              className="w-full py-2 text-xs font-bold text-stone-400 hover:text-stone-200"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
