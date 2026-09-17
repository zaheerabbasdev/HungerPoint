// ============================================================
// HungerPoint Web App — Promotions & Coupons
// Route: /promotions
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';

const PROMOTIONS_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER'];

const emptyForm = {
  code: '',
  description: '',
  type: 'PERCENTAGE',
  value: '',
  minOrderAmount: '',
  maxDiscount: '',
  usageLimit: '',
  perUserLimit: '1',
  expiresAt: '',
};

export default function PromotionsPage() {
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [coupons, setCoupons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState(emptyForm);
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
    if (!token || !user || !PROMOTIONS_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadCoupons = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchApi('/coupons/admin');
      if (res.success) setCoupons(res.data);
    } catch (err) {
      console.error('Failed to load coupons:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authorized) loadCoupons();
  }, [authorized, loadCoupons]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyForm);
    setShowForm(true);
  };

  const openEdit = (c: any) => {
    setEditingId(c.id);
    setForm({
      code: c.code,
      description: c.description || '',
      type: c.type,
      value: String(c.value),
      minOrderAmount: String(c.minOrderAmount ?? ''),
      maxDiscount: c.maxDiscount != null ? String(c.maxDiscount) : '',
      usageLimit: c.usageLimit != null ? String(c.usageLimit) : '',
      perUserLimit: String(c.perUserLimit ?? 1),
      expiresAt: c.expiresAt ? c.expiresAt.slice(0, 10) : '',
    });
    setShowForm(true);
  };

  const handleSave = async () => {
    if (!form.code.trim() || !form.value) return;
    setSaving(true);
    try {
      const payload = {
        code: form.code.trim(),
        description: form.description.trim() || undefined,
        type: form.type,
        value: Number(form.value),
        minOrderAmount: form.minOrderAmount ? Number(form.minOrderAmount) : 0,
        maxDiscount: form.maxDiscount ? Number(form.maxDiscount) : undefined,
        usageLimit: form.usageLimit ? Number(form.usageLimit) : undefined,
        perUserLimit: Number(form.perUserLimit) || 1,
        expiresAt: form.expiresAt || undefined,
      };

      const res = editingId
        ? await fetchApi(`/coupons/${editingId}`, { method: 'PUT', body: JSON.stringify(payload) })
        : await fetchApi('/coupons', { method: 'POST', body: JSON.stringify(payload) });

      if (res.success) {
        showToast(editingId ? 'Coupon updated' : 'Coupon created');
        setShowForm(false);
        await loadCoupons();
      } else {
        showToast(res.message || 'Failed to save coupon');
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to save coupon');
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivate = async (c: any) => {
    try {
      const res = await fetchApi(`/coupons/${c.id}`, { method: 'DELETE' });
      if (res.success) {
        showToast('Coupon deactivated');
        await loadCoupons();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to deactivate coupon');
    }
  };

  const handleReactivate = async (c: any) => {
    try {
      const res = await fetchApi(`/coupons/${c.id}`, { method: 'PUT', body: JSON.stringify({ isActive: true }) });
      if (res.success) {
        showToast('Coupon reactivated');
        await loadCoupons();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to reactivate coupon');
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
    <div className="min-h-screen bg-stone-950 text-stone-100">
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-stone-900 border border-amber-500/40 text-amber-400 text-xs font-bold px-4 py-2.5 rounded-xl shadow-xl">
          {toast}
        </div>
      )}

      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>🎟️</span> Promotions & Coupons</h1>
          </div>
          <button onClick={openCreate} className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl">
            + New Coupon
          </button>
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6">
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          {loading ? (
            <div className="text-center py-16 text-stone-500 text-sm">Loading coupons...</div>
          ) : coupons.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No coupons yet.</div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Code</th>
                  <th className="text-left px-4 py-2.5 font-bold">Description</th>
                  <th className="text-left px-4 py-2.5 font-bold">Discount</th>
                  <th className="text-left px-4 py-2.5 font-bold">Min Order</th>
                  <th className="text-left px-4 py-2.5 font-bold">Usage</th>
                  <th className="text-left px-4 py-2.5 font-bold">Status</th>
                  <th className="text-right px-4 py-2.5 font-bold">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {coupons.map((c) => (
                  <tr key={c.id} className="hover:bg-stone-800/30">
                    <td className="px-4 py-2.5 font-mono font-black text-amber-400">{c.code}</td>
                    <td className="px-4 py-2.5 text-stone-400 max-w-xs truncate">{c.description || '—'}</td>
                    <td className="px-4 py-2.5 text-stone-200 font-bold">
                      {c.type === 'PERCENTAGE' ? `${Number(c.value)}%` : `PKR ${Number(c.value)}`}
                      {c.maxDiscount && <span className="text-stone-500"> (max {Number(c.maxDiscount)})</span>}
                    </td>
                    <td className="px-4 py-2.5 text-stone-400">PKR {Number(c.minOrderAmount)}</td>
                    <td className="px-4 py-2.5 text-stone-400">{c.usageCount}{c.usageLimit ? `/${c.usageLimit}` : ''}</td>
                    <td className="px-4 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full border text-[10px] font-black uppercase ${
                        c.isActive ? 'bg-emerald-500/15 border-emerald-500/40 text-emerald-400' : 'bg-stone-800 border-stone-700 text-stone-500'
                      }`}>
                        {c.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-2.5 text-right space-x-1.5 whitespace-nowrap">
                      <button onClick={() => openEdit(c)} className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-stone-800 text-stone-300 hover:bg-stone-700">Edit</button>
                      {c.isActive ? (
                        <button onClick={() => handleDeactivate(c)} className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-red-500/15 text-red-400 hover:bg-red-500/25">Deactivate</button>
                      ) : (
                        <button onClick={() => handleReactivate(c)} className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-emerald-500/15 text-emerald-400 hover:bg-emerald-500/25">Reactivate</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Create/Edit Modal */}
      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-md bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-3 max-h-[90vh] overflow-y-auto">
            <h3 className="text-base font-black text-stone-100">{editingId ? 'Edit Coupon' : 'New Coupon'}</h3>
            <input type="text" placeholder="Code (e.g. WELCOME50)" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="text" placeholder="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <div className="grid grid-cols-2 gap-2">
              <select value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none">
                <option value="PERCENTAGE">Percentage</option>
                <option value="FIXED_AMOUNT">Fixed Amount</option>
              </select>
              <input type="number" placeholder="Value" value={form.value} onChange={(e) => setForm({ ...form, value: e.target.value })}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <input type="number" placeholder="Min order amount" value={form.minOrderAmount} onChange={(e) => setForm({ ...form, minOrderAmount: e.target.value })}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
              <input type="number" placeholder="Max discount" value={form.maxDiscount} onChange={(e) => setForm({ ...form, maxDiscount: e.target.value })}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <input type="number" placeholder="Usage limit (total)" value={form.usageLimit} onChange={(e) => setForm({ ...form, usageLimit: e.target.value })}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
              <input type="number" placeholder="Per-user limit" value={form.perUserLimit} onChange={(e) => setForm({ ...form, perUserLimit: e.target.value })}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            </div>
            <div>
              <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider block mb-1">Expires On</label>
              <input type="date" value={form.expiresAt} onChange={(e) => setForm({ ...form, expiresAt: e.target.value })}
                className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            </div>
            <div className="flex gap-2 pt-1">
              <button onClick={() => setShowForm(false)} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleSave} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Saving...' : editingId ? 'Save Changes' : 'Create Coupon'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
