// ============================================================
// HungerPoint Web App — Loyalty Program
// Route: /loyalty
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';

const LOYALTY_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER'];

export default function LoyaltyPage() {
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [accounts, setAccounts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const [showAdjust, setShowAdjust] = useState(false);
  const [selected, setSelected] = useState<any | null>(null);
  const [adjustForm, setAdjustForm] = useState({ points: '', type: 'ADJUSTED', notes: '' });
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
    if (!token || !user || !LOYALTY_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadAccounts = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchApi('/loyalty');
      if (res.success) setAccounts(res.data);
    } catch (err) {
      console.error('Failed to load loyalty accounts:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authorized) loadAccounts();
  }, [authorized, loadAccounts]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const openAdjust = (account: any) => {
    setSelected(account);
    setAdjustForm({ points: '', type: 'ADJUSTED', notes: '' });
    setShowAdjust(true);
  };

  const handleAdjust = async () => {
    if (!selected || !adjustForm.points) return;
    setSaving(true);
    try {
      const res = await fetchApi('/loyalty/adjust', {
        method: 'POST',
        body: JSON.stringify({
          customerId: selected.customerId,
          points: Number(adjustForm.points),
          type: adjustForm.type,
          notes: adjustForm.notes.trim() || undefined,
        }),
      });
      if (res.success) {
        showToast('Points adjusted');
        setShowAdjust(false);
        await loadAccounts();
      } else {
        showToast(res.message || 'Failed to adjust points');
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to adjust points');
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

  const filtered = accounts.filter((a) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    return a.customer?.user?.name?.toLowerCase().includes(q) || a.customer?.user?.phone?.includes(q);
  });

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
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>⭐</span> Loyalty Program</h1>
          </div>
          <input
            type="text"
            placeholder="Search by name or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-1.5 text-xs text-stone-200 outline-none focus:border-amber-500 w-56"
          />
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6">
        <p className="text-xs text-stone-500 mb-4">
          Customers automatically earn 1 point per PKR 100 spent when an order is marked <span className="text-amber-400 font-bold">Delivered</span>. Use Adjust to manually grant or redeem points.
        </p>
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          {loading ? (
            <div className="text-center py-16 text-stone-500 text-sm">Loading loyalty accounts...</div>
          ) : filtered.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No loyalty accounts found.</div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Customer</th>
                  <th className="text-right px-4 py-2.5 font-bold">Current Points</th>
                  <th className="text-right px-4 py-2.5 font-bold">Lifetime Points</th>
                  <th className="text-right px-4 py-2.5 font-bold">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {filtered.map((a) => (
                  <tr key={a.id} className="hover:bg-stone-800/30">
                    <td className="px-4 py-2.5">
                      <p className="font-bold text-stone-100">{a.customer?.user?.name || 'Unknown'}</p>
                      <p className="text-stone-500">{a.customer?.user?.phone}</p>
                    </td>
                    <td className="px-4 py-2.5 text-right font-black text-amber-400">{a.points}</td>
                    <td className="px-4 py-2.5 text-right text-stone-400">{a.lifetime}</td>
                    <td className="px-4 py-2.5 text-right">
                      <button onClick={() => openAdjust(a)} className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-stone-800 text-stone-300 hover:bg-stone-700">
                        Adjust
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Adjust Modal */}
      {showAdjust && selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-3">
            <h3 className="text-base font-black text-stone-100">Adjust Points — {selected.customer?.user?.name}</h3>
            <p className="text-xs text-stone-500">Current balance: <span className="text-amber-400 font-bold">{selected.points} points</span></p>
            <select value={adjustForm.type} onChange={(e) => setAdjustForm({ ...adjustForm, type: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none">
              <option value="ADJUSTED">Grant Points (Adjustment)</option>
              <option value="EARNED">Earned</option>
              <option value="REDEEMED">Redeem / Deduct</option>
            </select>
            <input type="number" placeholder="Points" value={adjustForm.points} onChange={(e) => setAdjustForm({ ...adjustForm, points: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="text" placeholder="Notes (optional)" value={adjustForm.notes} onChange={(e) => setAdjustForm({ ...adjustForm, notes: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <div className="flex gap-2 pt-1">
              <button onClick={() => setShowAdjust(false)} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleAdjust} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Saving...' : 'Apply'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
