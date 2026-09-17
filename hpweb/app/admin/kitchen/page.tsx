// ============================================================
// HungerPoint Web App — Kitchen Display Unit (KDU)
// ============================================================

'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { fetchApi } from '../../../lib/api';
import { getSocket } from '../../../lib/socket';
import Link from 'next/link';

const KITCHEN_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER', 'KITCHEN_STAFF'];

export default function KitchenDisplayPage() {
  const router = useRouter();
  const [queue, setQueue] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

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

    if (!token || !role || !KITCHEN_ALLOWED_ROLES.includes(role)) {
      router.replace('/admin');
      return;
    }
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  useEffect(() => {
    if (!authorized) return;

    async function loadKitchenQueue() {
      try {
        const res = await fetchApi('/kitchen/queue');
        if (res.success) setQueue(res.data);
      } catch (err) {
        console.error('Failed to load kitchen queue:', err);
      } finally {
        setLoading(false);
      }
    }
    loadKitchenQueue();

    // Real-time queue updates via Socket.IO (new orders + prepare/ready transitions)
    const socket = getSocket();
    const handleQueueEvent = () => loadKitchenQueue();
    socket.on('order.created', handleQueueEvent);
    socket.on('kitchen.queue_updated', handleQueueEvent);

    // Fallback safety-net refresh in case a socket event is missed/disconnected
    const interval = setInterval(loadKitchenQueue, 30000);

    return () => {
      socket.off('order.created', handleQueueEvent);
      socket.off('kitchen.queue_updated', handleQueueEvent);
      clearInterval(interval);
    };
  }, [authorized]);

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Checking access...</p>
      </div>
    );
  }

  if (!authorized) return null;

  const handleStartPrepare = async (orderId: string) => {
    try {
      const res = await fetchApi(`/kitchen/orders/${orderId}/prepare`, { method: 'PATCH' });
      if (res.success) {
        setQueue((prev) => prev.map((o) => (o.id === orderId ? { ...o, status: 'PREPARING' } : o)));
      }
    } catch (e: any) {
      alert(e.message || 'Error updating order');
    }
  };

  const handleMarkReady = async (orderId: string) => {
    try {
      const res = await fetchApi(`/kitchen/orders/${orderId}/ready`, { method: 'PATCH' });
      if (res.success) {
        setQueue((prev) => prev.filter((o) => o.id !== orderId));
      }
    } catch (e: any) {
      alert(e.message || 'Error updating order');
    }
  };

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex justify-between items-center pb-4 border-b border-stone-800">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">
              ← Back to Admin Dashboard
            </Link>
            <h1 className="text-2xl font-black text-amber-400 mt-1 flex items-center gap-2">
              <span>🍳</span> Kitchen Display Unit (KDU)
            </h1>
          </div>
          <div className="text-right">
            <span className="text-xs text-stone-400">Live Orders Queue:</span>
            <p className="text-lg font-black text-emerald-400">{queue.length} Ticket(s)</p>
          </div>
        </div>

        {/* Queue Cards */}
        {loading ? (
          <div className="text-center py-20 text-stone-500">Loading kitchen tickets...</div>
        ) : queue.length === 0 ? (
          <div className="text-center py-20 bg-stone-900/40 rounded-3xl border border-stone-800 text-stone-500 space-y-2">
            <span className="text-4xl block">✨</span>
            <p className="text-base font-bold text-stone-300">Kitchen queue is clear!</p>
            <p className="text-xs">New orders will appear here automatically.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {queue.map((order) => (
              <div
                key={order.id}
                className={`p-5 rounded-3xl border flex flex-col justify-between space-y-4 shadow-xl transition-all ${
                  order.status === 'PREPARING'
                    ? 'bg-amber-950/30 border-amber-500/50'
                    : 'bg-stone-900 border-stone-800'
                }`}
              >
                <div>
                  <div className="flex justify-between items-center pb-3 border-b border-stone-800">
                    <span className="font-mono font-black text-lg text-amber-400">{order.orderNumber}</span>
                    <span className="px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider bg-amber-500/20 text-amber-400 border border-amber-500/30">
                      {order.status}
                    </span>
                  </div>

                  <div className="py-3 space-y-2">
                    {order.items?.map((item: any) => (
                      <div key={item.id} className="flex justify-between text-xs font-bold text-stone-200">
                        <span>{item.quantity}x {item.product?.name}</span>
                        {item.variant?.name && <span className="text-amber-400">({item.variant.name})</span>}
                      </div>
                    ))}
                  </div>
                </div>

                <div className="pt-3 border-t border-stone-800 flex gap-2">
                  {order.status === 'CONFIRMED' || order.status === 'PENDING' ? (
                    <button
                      onClick={() => handleStartPrepare(order.id)}
                      className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 font-extrabold text-stone-950 text-xs rounded-xl transition-all"
                    >
                      Start Cooking 🔥
                    </button>
                  ) : (
                    <button
                      onClick={() => handleMarkReady(order.id)}
                      className="w-full py-2.5 bg-emerald-500 hover:bg-emerald-600 font-extrabold text-white text-xs rounded-xl transition-all shadow-lg"
                    >
                      Mark Ready for Dispatch ✓
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

      </div>
    </div>
  );
}
