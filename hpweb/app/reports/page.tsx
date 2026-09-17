// ============================================================
// HungerPoint Web App — Reports & Analytics
// Route: /reports
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';
import { useBranch } from '../../context/BranchContext';

const REPORTS_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER'];

export default function ReportsPage() {
  const router = useRouter();
  const { branches } = useBranch();

  const [currentUser, setCurrentUser] = useState<any>(null);
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [branchFilter, setBranchFilter] = useState('');
  const [overview, setOverview] = useState<any>(null);
  const [statusBreakdown, setStatusBreakdown] = useState<any[]>([]);
  const [topProducts, setTopProducts] = useState<any[]>([]);
  const [sourceBreakdown, setSourceBreakdown] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

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
    if (!token || !user || !REPORTS_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setCurrentUser(user);
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadReports = useCallback(async () => {
    setLoading(true);
    try {
      const qs = branchFilter ? `?branchId=${branchFilter}` : '';
      const [overviewRes, statusRes, productsRes, sourceRes] = await Promise.all([
        fetchApi(`/reports/overview${qs}`),
        fetchApi(`/reports/orders-by-status${qs}`),
        fetchApi(`/reports/top-products${qs}`),
        fetchApi(`/reports/orders-by-source${qs}`),
      ]);
      if (overviewRes.success) setOverview(overviewRes.data);
      if (statusRes.success) setStatusBreakdown(statusRes.data);
      if (productsRes.success) setTopProducts(productsRes.data);
      if (sourceRes.success) setSourceBreakdown(sourceRes.data);
    } catch (err) {
      console.error('Failed to load reports:', err);
    } finally {
      setLoading(false);
    }
  }, [branchFilter]);

  useEffect(() => {
    if (authorized) loadReports();
  }, [authorized, loadReports]);

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Checking access...</p>
      </div>
    );
  }
  if (!authorized) return null;

  const maxStatusCount = Math.max(1, ...statusBreakdown.map((s) => s.count));
  const maxSourceCount = Math.max(1, ...sourceBreakdown.map((s) => s.count));

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100">
      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 flex-wrap">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>📊</span> Reports & Analytics</h1>
          </div>
          {currentUser?.role !== 'BRANCH_MANAGER' && (
            <select
              value={branchFilter}
              onChange={(e) => setBranchFilter(e.target.value)}
              className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-1.5 text-xs text-stone-200 outline-none"
            >
              <option value="">All Branches</option>
              {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>
          )}
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6 space-y-6">
        {/* Overview stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: 'Total Orders', value: overview?.totalOrders, icon: '📦' },
            { label: 'Revenue (Delivered)', value: overview ? `PKR ${overview.totalRevenue.toFixed(0)}` : undefined, icon: '💰' },
            { label: 'Active Riders', value: overview?.activeRiders, icon: '🛵' },
            { label: 'Customers', value: overview?.totalCustomers, icon: '👥' },
          ].map((s) => (
            <div key={s.label} className="bg-stone-900 border border-stone-800 rounded-2xl p-4">
              <div className="text-2xl mb-1">{s.icon}</div>
              <p className="text-lg font-black text-stone-100">{loading ? '...' : s.value ?? '—'}</p>
              <p className="text-[11px] text-stone-400 font-bold uppercase tracking-wide">{s.label}</p>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Orders by status */}
          <div className="bg-stone-900 border border-stone-800 rounded-2xl p-5">
            <h2 className="text-sm font-extrabold text-stone-100 mb-4">Orders by Status</h2>
            {statusBreakdown.length === 0 ? (
              <p className="text-xs text-stone-500 text-center py-8">No order data yet.</p>
            ) : (
              <div className="space-y-2.5">
                {statusBreakdown.map((s) => (
                  <div key={s.status}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="font-bold text-stone-300">{s.status}</span>
                      <span className="text-stone-400">{s.count}</span>
                    </div>
                    <div className="h-2 bg-stone-800 rounded-full overflow-hidden">
                      <div className="h-full bg-gradient-to-r from-amber-500 to-orange-600 rounded-full" style={{ width: `${(s.count / maxStatusCount) * 100}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Orders by source */}
          <div className="bg-stone-900 border border-stone-800 rounded-2xl p-5">
            <h2 className="text-sm font-extrabold text-stone-100 mb-4">Orders by Source</h2>
            {sourceBreakdown.length === 0 ? (
              <p className="text-xs text-stone-500 text-center py-8">No order data yet.</p>
            ) : (
              <div className="space-y-2.5">
                {sourceBreakdown.map((s) => (
                  <div key={s.source}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="font-bold text-stone-300">{s.source.replace('_', ' ')}</span>
                      <span className="text-stone-400">{s.count}</span>
                    </div>
                    <div className="h-2 bg-stone-800 rounded-full overflow-hidden">
                      <div className="h-full bg-gradient-to-r from-emerald-500 to-teal-600 rounded-full" style={{ width: `${(s.count / maxSourceCount) * 100}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Top products */}
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          <div className="p-4 border-b border-stone-800">
            <h2 className="text-sm font-extrabold text-stone-100">Top Selling Products</h2>
          </div>
          {topProducts.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No sales data yet.</div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Product</th>
                  <th className="text-right px-4 py-2.5 font-bold">Units Sold</th>
                  <th className="text-right px-4 py-2.5 font-bold">Revenue</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {topProducts.map((p, idx) => (
                  <tr key={p.product?.id || idx} className="hover:bg-stone-800/30">
                    <td className="px-4 py-2.5 flex items-center gap-2.5">
                      {p.product?.image && <img src={p.product.image} alt="" className="w-8 h-8 rounded-lg object-cover" />}
                      <span className="font-bold text-stone-100">{p.product?.name || 'Unknown product'}</span>
                    </td>
                    <td className="px-4 py-2.5 text-right text-stone-300">{p.quantitySold}</td>
                    <td className="px-4 py-2.5 text-right font-bold text-amber-400">PKR {p.revenue.toFixed(0)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Recent orders */}
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          <div className="p-4 border-b border-stone-800">
            <h2 className="text-sm font-extrabold text-stone-100">Recent Orders</h2>
          </div>
          {!overview?.recentOrders || overview.recentOrders.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No orders yet.</div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Order #</th>
                  <th className="text-left px-4 py-2.5 font-bold">Customer</th>
                  <th className="text-left px-4 py-2.5 font-bold">Status</th>
                  <th className="text-right px-4 py-2.5 font-bold">Total</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {overview.recentOrders.map((o: any) => (
                  <tr key={o.id} className="hover:bg-stone-800/30">
                    <td className="px-4 py-2.5 font-mono font-bold text-amber-400">{o.orderNumber}</td>
                    <td className="px-4 py-2.5 text-stone-300">{o.customer?.user?.name || 'Walk-in'}</td>
                    <td className="px-4 py-2.5 text-stone-400">{o.status}</td>
                    <td className="px-4 py-2.5 text-right font-bold text-stone-100">PKR {Number(o.total).toFixed(0)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
