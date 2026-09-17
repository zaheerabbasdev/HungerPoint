// ============================================================
// HungerPoint Web App — Inventory
// Route: /inventory
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';
import { useBranch } from '../../context/BranchContext';

const INVENTORY_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER'];

const TRANSACTION_TYPES = ['STOCK_IN', 'STOCK_OUT', 'CONSUMPTION', 'WASTE', 'ADJUSTMENT', 'TRANSFER_IN', 'TRANSFER_OUT'];

export default function InventoryPage() {
  const router = useRouter();
  const { branches, selectedBranchId, setSelectedBranchId } = useBranch();

  const [currentUser, setCurrentUser] = useState<any>(null);
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [items, setItems] = useState<any[]>([]);
  const [stock, setStock] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const [showAddItem, setShowAddItem] = useState(false);
  const [newItem, setNewItem] = useState({ name: '', unit: 'kg', minStock: '' });

  const [showAdjust, setShowAdjust] = useState(false);
  const [adjustForm, setAdjustForm] = useState({ itemId: '', type: 'STOCK_IN', quantity: '', notes: '' });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('hp_access_token');
    const userStr = localStorage.getItem('hp_user');
    let user: any = null;
    if (userStr) {
      try {
        user = JSON.parse(userStr);
      } catch {
        user = null;
      }
    }
    if (!token || !user || !INVENTORY_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setCurrentUser(user);
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const effectiveBranchId = currentUser?.role === 'BRANCH_MANAGER' ? currentUser.branchId : selectedBranchId;

  const loadData = useCallback(async () => {
    if (!effectiveBranchId) return;
    setLoading(true);
    try {
      const [itemsRes, stockRes] = await Promise.all([
        fetchApi('/inventory/items'),
        fetchApi(`/inventory/branch/${effectiveBranchId}`),
      ]);
      if (itemsRes.success) setItems(itemsRes.data);
      if (stockRes.success) setStock(stockRes.data);
    } catch (err) {
      console.error('Failed to load inventory:', err);
    } finally {
      setLoading(false);
    }
  }, [effectiveBranchId]);

  useEffect(() => {
    if (authorized) loadData();
  }, [authorized, loadData]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const handleAddItem = async () => {
    if (!newItem.name.trim() || !newItem.unit.trim()) return;
    setSaving(true);
    try {
      const res = await fetchApi('/inventory/items', {
        method: 'POST',
        body: JSON.stringify({
          name: newItem.name.trim(),
          unit: newItem.unit.trim(),
          minStock: Number(newItem.minStock) || 0,
        }),
      });
      if (res.success) {
        showToast('Inventory item added');
        setShowAddItem(false);
        setNewItem({ name: '', unit: 'kg', minStock: '' });
        await loadData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to add item');
    } finally {
      setSaving(false);
    }
  };

  const handleAdjustStock = async () => {
    if (!adjustForm.itemId || !adjustForm.quantity || !effectiveBranchId) return;
    setSaving(true);
    try {
      const res = await fetchApi('/inventory/stock', {
        method: 'POST',
        body: JSON.stringify({
          itemId: adjustForm.itemId,
          branchId: effectiveBranchId,
          type: adjustForm.type,
          quantity: Number(adjustForm.quantity),
          notes: adjustForm.notes.trim() || undefined,
        }),
      });
      if (res.success) {
        showToast('Stock updated');
        setShowAdjust(false);
        setAdjustForm({ itemId: '', type: 'STOCK_IN', quantity: '', notes: '' });
        await loadData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update stock');
    } finally {
      setSaving(false);
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

  const stockByItemId = new Map(stock.map((s) => [s.itemId, s]));

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100">
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-stone-900 border border-amber-500/40 text-amber-400 text-xs font-bold px-4 py-2.5 rounded-xl shadow-xl">
          {toast}
        </div>
      )}

      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 flex-wrap">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>📦</span> Inventory</h1>
          </div>
          <div className="flex items-center gap-2">
            {currentUser?.role !== 'BRANCH_MANAGER' && (
              <select
                value={selectedBranchId ?? ''}
                onChange={(e) => setSelectedBranchId(e.target.value)}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-1.5 text-xs text-stone-200 outline-none"
              >
                {branches.map((b) => (
                  <option key={b.id} value={b.id}>{b.name}</option>
                ))}
              </select>
            )}
            <button onClick={() => setShowAddItem(true)} className="px-3 py-1.5 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl">
              + Item Type
            </button>
            <button onClick={() => setShowAdjust(true)} className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl">
              + Stock Adjustment
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6">
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          {loading ? (
            <div className="text-center py-16 text-stone-500 text-sm">Loading inventory...</div>
          ) : items.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No inventory items defined yet. Add one to get started.</div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Item</th>
                  <th className="text-left px-4 py-2.5 font-bold">Unit</th>
                  <th className="text-right px-4 py-2.5 font-bold">Current Stock</th>
                  <th className="text-right px-4 py-2.5 font-bold">Min Stock</th>
                  <th className="text-center px-4 py-2.5 font-bold">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {items.map((item) => {
                  const s = stockByItemId.get(item.id);
                  const qty = Number(s?.quantity ?? 0);
                  const minStock = Number(item.minStock);
                  const isLow = qty < minStock;
                  return (
                    <tr key={item.id} className="hover:bg-stone-800/30">
                      <td className="px-4 py-2.5 font-bold text-stone-100">{item.name}</td>
                      <td className="px-4 py-2.5 text-stone-400">{item.unit}</td>
                      <td className="px-4 py-2.5 text-right font-mono text-stone-200">{qty}</td>
                      <td className="px-4 py-2.5 text-right font-mono text-stone-500">{minStock}</td>
                      <td className="px-4 py-2.5 text-center">
                        {isLow ? (
                          <span className="px-2 py-0.5 rounded-full bg-red-500/15 border border-red-500/40 text-red-400 text-[10px] font-black uppercase">Low Stock</span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-full bg-emerald-500/15 border border-emerald-500/40 text-emerald-400 text-[10px] font-black uppercase">OK</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Add Item Modal */}
      {showAddItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-4">
            <h3 className="text-base font-black text-stone-100">New Inventory Item</h3>
            <input
              type="text"
              placeholder="Item name (e.g. Beef Patty)"
              value={newItem.name}
              onChange={(e) => setNewItem({ ...newItem, name: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500"
            />
            <input
              type="text"
              placeholder="Unit (e.g. kg, piece, litre)"
              value={newItem.unit}
              onChange={(e) => setNewItem({ ...newItem, unit: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500"
            />
            <input
              type="number"
              placeholder="Minimum stock threshold"
              value={newItem.minStock}
              onChange={(e) => setNewItem({ ...newItem, minStock: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500"
            />
            <div className="flex gap-2">
              <button onClick={() => setShowAddItem(false)} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleAddItem} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Saving...' : 'Add Item'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Stock Adjustment Modal */}
      {showAdjust && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-4">
            <h3 className="text-base font-black text-stone-100">Stock Adjustment</h3>
            <select
              value={adjustForm.itemId}
              onChange={(e) => setAdjustForm({ ...adjustForm, itemId: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none"
            >
              <option value="">Select item...</option>
              {items.map((i) => (
                <option key={i.id} value={i.id}>{i.name} ({i.unit})</option>
              ))}
            </select>
            <select
              value={adjustForm.type}
              onChange={(e) => setAdjustForm({ ...adjustForm, type: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none"
            >
              {TRANSACTION_TYPES.map((t) => (
                <option key={t} value={t}>{t.replace('_', ' ')}</option>
              ))}
            </select>
            <input
              type="number"
              placeholder="Quantity"
              value={adjustForm.quantity}
              onChange={(e) => setAdjustForm({ ...adjustForm, quantity: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500"
            />
            <input
              type="text"
              placeholder="Notes (optional)"
              value={adjustForm.notes}
              onChange={(e) => setAdjustForm({ ...adjustForm, notes: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500"
            />
            <div className="flex gap-2">
              <button onClick={() => setShowAdjust(false)} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleAdjustStock} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
