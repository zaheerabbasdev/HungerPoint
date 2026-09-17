// ============================================================
// HungerPoint Web App — Rider Management
// Route: /riders
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';
import { useBranch } from '../../context/BranchContext';

const RIDERS_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER'];

const STATUS_STYLES: Record<string, string> = {
  ONLINE: 'bg-emerald-500/15 border-emerald-500/40 text-emerald-400',
  ON_DELIVERY: 'bg-amber-500/15 border-amber-500/40 text-amber-400',
  OFFLINE: 'bg-stone-800 border-stone-700 text-stone-500',
};

export default function RidersPage() {
  const router = useRouter();
  const { branches } = useBranch();

  const [currentUser, setCurrentUser] = useState<any>(null);
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [riders, setRiders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');

  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState({ name: '', phone: '', password: '', branchId: '', vehicle: '', licensePlate: '' });
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
    if (!token || !user || !RIDERS_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setCurrentUser(user);
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadRiders = useCallback(async () => {
    setLoading(true);
    try {
      const qs = statusFilter ? `?status=${statusFilter}` : '';
      const res = await fetchApi(`/riders${qs}`);
      if (res.success) setRiders(res.data);
    } catch (err) {
      console.error('Failed to load riders:', err);
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    if (authorized) loadRiders();
  }, [authorized, loadRiders]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const handleCreate = async () => {
    if (!form.name.trim() || !form.phone.trim() || !form.password.trim()) return;
    setSaving(true);
    try {
      const res = await fetchApi('/riders', {
        method: 'POST',
        body: JSON.stringify({
          name: form.name.trim(),
          phone: form.phone.trim(),
          password: form.password,
          branchId: form.branchId || currentUser?.branchId || undefined,
          vehicle: form.vehicle.trim() || undefined,
          licensePlate: form.licensePlate.trim() || undefined,
        }),
      });
      if (res.success) {
        showToast('Rider created successfully');
        setShowCreate(false);
        setForm({ name: '', phone: '', password: '', branchId: '', vehicle: '', licensePlate: '' });
        await loadRiders();
      } else {
        showToast(res.message || 'Failed to create rider');
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to create rider');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (rider: any) => {
    try {
      const res = await fetchApi(`/riders/${rider.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !rider.isActive }),
      });
      if (res.success) {
        showToast(rider.isActive ? 'Rider deactivated' : 'Rider activated');
        await loadRiders();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update rider');
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
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 flex-wrap">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>🛵</span> Rider Management</h1>
          </div>
          <div className="flex items-center gap-2">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-1.5 text-xs text-stone-200 outline-none"
            >
              <option value="">All statuses</option>
              <option value="ONLINE">Online</option>
              <option value="ON_DELIVERY">On Delivery</option>
              <option value="OFFLINE">Offline</option>
            </select>
            <button onClick={() => setShowCreate(true)} className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl">
              + New Rider
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6">
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          {loading ? (
            <div className="text-center py-16 text-stone-500 text-sm">Loading riders...</div>
          ) : riders.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No riders found.</div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Rider</th>
                  <th className="text-left px-4 py-2.5 font-bold">Branch</th>
                  <th className="text-left px-4 py-2.5 font-bold">Vehicle</th>
                  <th className="text-left px-4 py-2.5 font-bold">Status</th>
                  <th className="text-left px-4 py-2.5 font-bold">Active Delivery</th>
                  <th className="text-right px-4 py-2.5 font-bold">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {riders.map((r) => (
                  <tr key={r.id} className="hover:bg-stone-800/30">
                    <td className="px-4 py-2.5">
                      <p className="font-bold text-stone-100">{r.user?.name}</p>
                      <p className="text-stone-500">{r.user?.phone}</p>
                    </td>
                    <td className="px-4 py-2.5 text-stone-400">{r.branch?.name || '—'}</td>
                    <td className="px-4 py-2.5 text-stone-400">{r.vehicle || '—'} {r.licensePlate ? `(${r.licensePlate})` : ''}</td>
                    <td className="px-4 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full border text-[10px] font-black uppercase ${STATUS_STYLES[r.status] || STATUS_STYLES.OFFLINE}`}>
                        {r.status}
                      </span>
                      {!r.isActive && <span className="ml-1.5 text-[10px] text-red-400 font-bold">Deactivated</span>}
                    </td>
                    <td className="px-4 py-2.5 text-stone-400">
                      {r.deliveries?.[0]?.order?.orderNumber || '—'}
                    </td>
                    <td className="px-4 py-2.5 text-right">
                      <button
                        onClick={() => handleToggleActive(r)}
                        className={`px-2.5 py-1 rounded-lg text-[10px] font-bold ${
                          r.isActive ? 'bg-red-500/15 text-red-400 hover:bg-red-500/25' : 'bg-emerald-500/15 text-emerald-400 hover:bg-emerald-500/25'
                        }`}
                      >
                        {r.isActive ? 'Deactivate' : 'Activate'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Create Rider Modal */}
      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-3">
            <h3 className="text-base font-black text-stone-100">New Rider</h3>
            <input type="text" placeholder="Full name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="text" placeholder="Phone number" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="password" placeholder="Temporary password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            {currentUser?.role !== 'BRANCH_MANAGER' && (
              <select value={form.branchId} onChange={(e) => setForm({ ...form, branchId: e.target.value })}
                className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none">
                <option value="">Select branch...</option>
                {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            )}
            <input type="text" placeholder="Vehicle (e.g. Motorbike)" value={form.vehicle} onChange={(e) => setForm({ ...form, vehicle: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="text" placeholder="License plate" value={form.licensePlate} onChange={(e) => setForm({ ...form, licensePlate: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <div className="flex gap-2 pt-1">
              <button onClick={() => setShowCreate(false)} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleCreate} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Creating...' : 'Create Rider'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
