// ============================================================
// HungerPoint Web App — Admin & Branch Manager Dashboard
// ============================================================

'use client';

import React, { useState, useEffect } from 'react';
import { fetchApi } from '../../lib/api';
import Link from 'next/link';

export default function AdminDashboardPage() {
  const [overview, setOverview] = useState<any>(null);
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadAdminData() {
      try {
        const [ovRes, ordRes] = await Promise.all([
          fetchApi('/reports/overview'),
          fetchApi('/orders'),
        ]);
        if (ovRes.success) setOverview(ovRes.data);
        if (ordRes.success) setOrders(ordRes.orders || []);
      } catch (err) {
        console.error('Failed to load admin data:', err);
      } finally {
        setLoading(false);
      }
    }
    loadAdminData();
  }, []);

  const handleUpdateStatus = async (orderId: string, status: string) => {
    try {
      const res = await fetchApi(`/orders/${orderId}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      if (res.success) {
        setOrders((prev) =>
          prev.map((o) => (o.id === orderId ? { ...o, status } : o))
        );
      }
    } catch (e: any) {
      alert(e.message || 'Failed to update order status');
    }
  };

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 p-6 sm:p-8">
      <div className="max-w-7xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 pb-6 border-b border-stone-800">
          <div>
            <div className="flex items-center gap-3">
              <Link href="/" className="text-xs text-amber-400 font-bold hover:underline">
                ← Back to Storefront
              </Link>
            </div>
            <h1 className="text-3xl font-black bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent mt-1">
              HungerPoint Operations Dashboard
            </h1>
            <p className="text-xs text-stone-400">Branch Management, Live Orders & Fleet Control</p>
          </div>

          <div className="flex gap-2">
            <Link
              href="/admin/kitchen"
              className="px-4 py-2.5 bg-amber-500/10 border border-amber-500/30 text-amber-400 font-bold text-xs rounded-xl hover:bg-amber-500/20 transition-all"
            >
              🍳 Kitchen Display Unit (KDU)
            </Link>
          </div>
        </div>

        {/* Overview Stat Cards */}
        {loading ? (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-28 bg-stone-900 rounded-2xl animate-pulse" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-stone-900 border border-stone-800 p-5 rounded-2xl space-y-1">
              <span className="text-xs text-stone-400 font-bold uppercase">Total Revenue</span>
              <p className="text-2xl font-black text-amber-400">
                PKR {Number(overview?.totalRevenue || 0).toLocaleString()}
              </p>
            </div>
            <div className="bg-stone-900 border border-stone-800 p-5 rounded-2xl space-y-1">
              <span className="text-xs text-stone-400 font-bold uppercase">Total Orders</span>
              <p className="text-2xl font-black text-stone-100">{overview?.totalOrders || 0}</p>
            </div>
            <div className="bg-stone-900 border border-stone-800 p-5 rounded-2xl space-y-1">
              <span className="text-xs text-stone-400 font-bold uppercase">Pending Orders</span>
              <p className="text-2xl font-black text-orange-400">{overview?.pendingOrders || 0}</p>
            </div>
            <div className="bg-stone-900 border border-stone-800 p-5 rounded-2xl space-y-1">
              <span className="text-xs text-stone-400 font-bold uppercase">Active Riders</span>
              <p className="text-2xl font-black text-emerald-400">{overview?.activeRiders || 0}</p>
            </div>
          </div>
        )}

        {/* Live Orders Table */}
        <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 space-y-4 shadow-xl">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-extrabold text-stone-100">Live Orders Management</h3>
            <span className="text-xs text-stone-400 font-semibold">{orders.length} orders total</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-stone-800 text-stone-400 font-bold uppercase text-[10px] tracking-wider">
                  <th className="py-3 px-4">Order #</th>
                  <th className="py-3 px-4">Customer</th>
                  <th className="py-3 px-4">Branch</th>
                  <th className="py-3 px-4">Total</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800/60 font-medium">
                {orders.map((o) => (
                  <tr key={o.id} className="hover:bg-stone-800/40 transition-colors">
                    <td className="py-3.5 px-4 font-mono font-bold text-amber-400">{o.orderNumber}</td>
                    <td className="py-3.5 px-4">{o.customer?.user?.name || 'Walk-in'}</td>
                    <td className="py-3.5 px-4 text-stone-400">{o.branch?.name}</td>
                    <td className="py-3.5 px-4 font-bold text-stone-100">PKR {Number(o.total).toFixed(2)}</td>
                    <td className="py-3.5 px-4">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider bg-orange-500/20 text-orange-400 border border-orange-500/30">
                        {o.status}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <select
                        value={o.status}
                        onChange={(e) => handleUpdateStatus(o.id, e.target.value)}
                        className="bg-stone-800 border border-stone-700 text-stone-200 text-[11px] rounded-lg px-2 py-1 outline-none font-bold"
                      >
                        <option value="PENDING">PENDING</option>
                        <option value="CONFIRMED">CONFIRMED</option>
                        <option value="PREPARING">PREPARING</option>
                        <option value="READY">READY</option>
                        <option value="OUT_FOR_DELIVERY">OUT_FOR_DELIVERY</option>
                        <option value="DELIVERED">DELIVERED</option>
                        <option value="CANCELLED">CANCELLED</option>
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </div>
  );
}
