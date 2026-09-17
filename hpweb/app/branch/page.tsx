// ============================================================
// HungerPoint Web App — Branch Dashboard
// Route: /branch — scoped to the manager's own branch (enforced server-side)
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';

const BRANCH_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER', 'BRANCH_STAFF'];

interface Overview {
  totalOrders: number;
  totalRevenue: number;
  pendingOrders: number;
  activeRiders: number;
  totalProducts: number;
  totalCustomers: number;
  recentOrders: any[];
}

export default function BranchDashboardPage() {
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [currentUser, setCurrentUser] = useState<any>(null);

  const [overview, setOverview] = useState<Overview | null>(null);
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [branchName, setBranchName] = useState<string>('');

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
    if (!token || !user || !BRANCH_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setCurrentUser(user);
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadData = useCallback(async () => {
    try {
      const [overviewRes, ordersRes] = await Promise.all([
        fetchApi('/reports/overview'),
        fetchApi('/orders?limit=20'),
      ]);
      if (overviewRes.success) setOverview(overviewRes.data);
      if (ordersRes.success) setOrders(ordersRes.orders || []);
    } catch (err) {
      console.error('Failed to load branch dashboard:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!authorized) return;
    loadData();
    if (currentUser?.branchId) {
      fetchApi(`/branches/${currentUser.branchId}`)
        .then((res) => res.success && setBranchName(res.data.name))
        .catch(() => {});
    }
  }, [authorized, currentUser, loadData]);

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Checking access...</p>
      </div>
    );
  }
  if (!authorized) return null;

  const stats = [
    { label: 'Total Orders', value: overview?.totalOrders ?? '—', icon: '📦' },
    { label: 'Revenue (Delivered)', value: overview ? `PKR ${overview.totalRevenue.toFixed(0)}` : '—', icon: '💰' },
    { label: 'Pending Orders', value: overview?.pendingOrders ?? '—', icon: '⏳' },
    { label: 'Active Products', value: overview?.totalProducts ?? '—', icon: '🍔' },
  ];

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100">
      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">
              ← Back to Admin Dashboard
            </Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2">
              <span>🏬</span> Branch Dashboard {branchName && <span className="text-amber-400">— {branchName}</span>}
            </h1>
          </div>
          <div className="flex items-center gap-2">
            <Link href="/pos" className="px-3 py-1.5 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl">POS</Link>
            <Link href="/admin/kitchen" className="px-3 py-1.5 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl">Kitchen</Link>
            <Link href="/inventory" className="px-3 py-1.5 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl">Inventory</Link>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6 space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((s) => (
            <div key={s.label} className="bg-stone-900 border border-stone-800 rounded-2xl p-4">
              <div className="text-2xl mb-1">{s.icon}</div>
              <p className="text-lg font-black text-stone-100">{loading ? '...' : s.value}</p>
              <p className="text-[11px] text-stone-400 font-bold uppercase tracking-wide">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Orders */}
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          <div className="p-4 border-b border-stone-800 flex justify-between items-center">
            <h2 className="text-sm font-extrabold text-stone-100">Branch Orders</h2>
            <button onClick={loadData} className="text-xs font-bold text-amber-400 hover:underline">Refresh</button>
          </div>
          {loading ? (
            <div className="text-center py-16 text-stone-500 text-sm">Loading orders...</div>
          ) : orders.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No orders yet for this branch.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                  <tr>
                    <th className="text-left px-4 py-2.5 font-bold">Order #</th>
                    <th className="text-left px-4 py-2.5 font-bold">Customer</th>
                    <th className="text-left px-4 py-2.5 font-bold">Source</th>
                    <th className="text-left px-4 py-2.5 font-bold">Status</th>
                    <th className="text-right px-4 py-2.5 font-bold">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-800">
                  {orders.map((o) => (
                    <tr key={o.id} className="hover:bg-stone-800/30">
                      <td className="px-4 py-2.5 font-mono font-bold text-amber-400">{o.orderNumber}</td>
                      <td className="px-4 py-2.5 text-stone-300">{o.customer?.user?.name || 'Walk-in'}</td>
                      <td className="px-4 py-2.5 text-stone-400">{o.source}</td>
                      <td className="px-4 py-2.5">
                        <span className="px-2 py-0.5 rounded-full bg-stone-800 border border-stone-700 text-stone-300 text-[10px] font-black uppercase">
                          {o.status}
                        </span>
                      </td>
                      <td className="px-4 py-2.5 text-right font-bold text-stone-100">PKR {Number(o.total).toFixed(0)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
