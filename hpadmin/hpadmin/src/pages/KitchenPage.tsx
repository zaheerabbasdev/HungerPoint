// ============================================================
// HungerPoint Web App — Kitchen Display Unit (KDU)
// Route: /kitchen
//
// Fully separate from the Admin console: its own login screen, its own
// browser session (hp_kitchen_* keys) and KITCHEN_STAFF accounts only.
// Admin / Branch Manager cannot sign in here.
// ============================================================

import React, { useState, useEffect } from 'react';
import { fetchApi, KITCHEN_SESSION } from '../lib/api';
import { getKitchenSocket, resetKitchenSocket } from '../lib/socket';

const kitchenFetch = (endpoint: string, options: RequestInit = {}) =>
  fetchApi(endpoint, options, KITCHEN_SESSION);

function clearKitchenSession() {
  localStorage.removeItem(KITCHEN_SESSION.access);
  localStorage.removeItem(KITCHEN_SESSION.refresh);
  localStorage.removeItem(KITCHEN_SESSION.user);
}

export default function KitchenDisplayPage() {
  const [kitchenUser, setKitchenUser] = useState<any>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [queue, setQueue] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  // Prep minutes the cook picks per ticket before pressing Start Cooking.
  const [prepMinutes, setPrepMinutes] = useState<Record<string, number>>({});
  const [now, setNow] = useState(Date.now());

  // Login form
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [loginError, setLoginError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // ─── Restore kitchen session ─────────────────────────────────
  useEffect(() => {
    const token = localStorage.getItem(KITCHEN_SESSION.access);
    const userStr = localStorage.getItem(KITCHEN_SESSION.user);
    if (token && userStr) {
      try {
        const u = JSON.parse(userStr);
        if (u?.role === 'KITCHEN_STAFF') {
          setKitchenUser(u);
        } else {
          clearKitchenSession();
        }
      } catch {
        clearKitchenSession();
      }
    }
    setCheckingAuth(false);

    const handleExpired = () => {
      resetKitchenSocket();
      setKitchenUser(null);
      setLoginError('Your session has expired. Please sign in again.');
    };
    window.addEventListener(KITCHEN_SESSION.expiredEvent, handleExpired);
    return () => window.removeEventListener(KITCHEN_SESSION.expiredEvent, handleExpired);
  }, []);

  // ─── Queue + realtime ────────────────────────────────────────
  useEffect(() => {
    if (!kitchenUser) return;

    async function loadKitchenQueue() {
      try {
        const res = await kitchenFetch('/kitchen/queue');
        if (res.success) setQueue(res.data);
      } catch (err) {
        console.error('Failed to load kitchen queue:', err);
      } finally {
        setLoading(false);
      }
    }
    loadKitchenQueue();

    const socket = getKitchenSocket();
    const handleQueueEvent = () => loadKitchenQueue();
    socket.on('order.created', handleQueueEvent);
    socket.on('kitchen.queue_updated', handleQueueEvent);

    // Fallback safety-net refresh in case a socket event is missed/disconnected
    const interval = setInterval(loadKitchenQueue, 30000);
    const tick = setInterval(() => setNow(Date.now()), 15000);

    return () => {
      socket.off('order.created', handleQueueEvent);
      socket.off('kitchen.queue_updated', handleQueueEvent);
      clearInterval(interval);
      clearInterval(tick);
    };
  }, [kitchenUser]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setLoginError('');
    try {
      const id = identifier.trim();
      const body = id.includes('@')
        ? { email: id, password }
        : { phone: id, password };

      const res = await kitchenFetch('/auth/login', {
        method: 'POST',
        body: JSON.stringify(body),
      });

      if (!res.success || !res.data) throw new Error(res.message || 'Login failed');

      const { user, accessToken, refreshToken } = res.data;
      if (user.role !== 'KITCHEN_STAFF') {
        throw new Error('This login is for Kitchen Staff only. Admins sign in at /admin.');
      }

      localStorage.setItem(KITCHEN_SESSION.access, accessToken);
      if (refreshToken) localStorage.setItem(KITCHEN_SESSION.refresh, refreshToken);
      localStorage.setItem(KITCHEN_SESSION.user, JSON.stringify(user));
      resetKitchenSocket();
      setLoading(true);
      setKitchenUser(user);
      setPassword('');
    } catch (err: any) {
      setLoginError(err.message || 'Authentication failed');
    } finally {
      setSubmitting(false);
    }
  };

  const handleLogout = () => {
    clearKitchenSession();
    resetKitchenSocket();
    setQueue([]);
    setKitchenUser(null);
  };

  const handleStartPrepare = async (orderId: string) => {
    try {
      const res = await kitchenFetch(`/kitchen/orders/${orderId}/prepare`, {
        method: 'PATCH',
        body: JSON.stringify({ estimatedPrepTime: prepMinutes[orderId] ?? 15 }),
      });
      if (res.success) {
        setQueue((prev) => prev.map((o) => (o.id === orderId ? { ...o, ...res.data } : o)));
      }
    } catch (e: any) {
      alert(e.message || 'Error updating order');
    }
  };

  const handleExtend = async (orderId: string, extraMinutes: number) => {
    try {
      const res = await kitchenFetch(`/kitchen/orders/${orderId}/extend`, {
        method: 'PATCH',
        body: JSON.stringify({ extraMinutes }),
      });
      if (res.success) {
        setQueue((prev) => prev.map((o) => (o.id === orderId ? { ...o, ...res.data } : o)));
      }
    } catch (e: any) {
      alert(e.message || 'Error updating order');
    }
  };

  // Minutes left until the food is due (cooking start + prep time).
  const minutesLeft = (order: any): number | null => {
    if (!order.acceptedAt || !order.estimatedPrepTime) return null;
    const due = new Date(order.acceptedAt).getTime() + order.estimatedPrepTime * 60_000;
    return Math.round((due - now) / 60_000);
  };

  const handleMarkReady = async (orderId: string) => {
    try {
      const res = await kitchenFetch(`/kitchen/orders/${orderId}/ready`, { method: 'PATCH' });
      if (res.success) {
        setQueue((prev) => prev.filter((o) => o.id !== orderId));
      }
    } catch (e: any) {
      alert(e.message || 'Error updating order');
    }
  };

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Loading...</p>
      </div>
    );
  }

  // ─── Kitchen login ───────────────────────────────────────────
  if (!kitchenUser) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center p-6">
        <form
          onSubmit={handleLogin}
          className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-8 space-y-5 shadow-xl"
        >
          <div className="text-center space-y-1">
            <span className="text-4xl block">🍳</span>
            <h1 className="text-xl font-black text-amber-400">Kitchen Login</h1>
            <p className="text-xs text-stone-500">Kitchen Display Unit — staff only</p>
          </div>

          {loginError && (
            <p className="text-xs font-bold text-red-400 bg-red-500/10 border border-red-500/30 rounded-xl px-3 py-2">
              {loginError}
            </p>
          )}

          <input
            type="text"
            required
            value={identifier}
            onChange={(e) => setIdentifier(e.target.value)}
            placeholder="Email or phone"
            autoComplete="username"
            className="w-full px-4 py-2.5 bg-stone-950 border border-stone-800 rounded-xl text-sm focus:outline-none focus:border-amber-500"
          />
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
            autoComplete="current-password"
            className="w-full px-4 py-2.5 bg-stone-950 border border-stone-800 rounded-xl text-sm focus:outline-none focus:border-amber-500"
          />
          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 disabled:opacity-50 font-extrabold text-stone-950 text-sm rounded-xl transition-all"
          >
            {submitting ? 'Signing in...' : 'Sign in to Kitchen'}
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">

        {/* Header */}
        <div className="flex justify-between items-center pb-4 border-b border-stone-800">
          <div>
            <h1 className="text-2xl font-black text-amber-400 flex items-center gap-2">
              <span>🍳</span> Kitchen Display Unit (KDU)
            </h1>
            <p className="text-xs text-stone-500 mt-1">Signed in as {kitchenUser.name}</p>
          </div>
          <div className="flex items-center gap-6">
            <div className="text-right">
              <span className="text-xs text-stone-400">Live Orders Queue:</span>
              <p className="text-lg font-black text-emerald-400">{queue.length} Ticket(s)</p>
            </div>
            <button
              onClick={handleLogout}
              className="px-3 py-1.5 bg-stone-800 hover:bg-stone-700 text-stone-300 text-xs font-bold rounded-xl"
            >
              Log out
            </button>
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

                <div className="pt-3 border-t border-stone-800 space-y-3">
                  {order.status === 'CONFIRMED' || order.status === 'PENDING' ? (
                    <>
                      <div>
                        <p className="text-[10px] font-bold uppercase tracking-wider text-stone-500 mb-1.5">Preparation time (minutes)</p>
                        <div className="flex gap-1.5">
                          {[10, 15, 20, 30, 45].map((m) => (
                            <button
                              key={m}
                              onClick={() => setPrepMinutes((p) => ({ ...p, [order.id]: m }))}
                              className={`flex-1 py-1.5 rounded-lg text-xs font-black border transition-all ${
                                (prepMinutes[order.id] ?? 15) === m
                                  ? 'bg-amber-500 text-stone-950 border-amber-500'
                                  : 'bg-stone-950 text-stone-300 border-stone-700 hover:border-amber-500'
                              }`}
                            >
                              {m}
                            </button>
                          ))}
                        </div>
                      </div>
                      <button
                        onClick={() => handleStartPrepare(order.id)}
                        className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 font-extrabold text-stone-950 text-xs rounded-xl transition-all"
                      >
                        Start Cooking — {prepMinutes[order.id] ?? 15} min 🔥
                      </button>
                    </>
                  ) : (
                    <>
                      {minutesLeft(order) !== null && (
                        <div className="flex items-center justify-between text-xs">
                          <span className={`font-black ${(minutesLeft(order) as number) < 0 ? 'text-red-400' : 'text-amber-400'}`}>
                            {(minutesLeft(order) as number) < 0
                              ? `Running late by ${Math.abs(minutesLeft(order) as number)} min`
                              : `Due in ${minutesLeft(order)} min`}
                          </span>
                          <button
                            onClick={() => handleExtend(order.id, 5)}
                            className="px-2.5 py-1 bg-stone-800 hover:bg-stone-700 text-stone-300 font-bold rounded-lg"
                          >
                            +5 min
                          </button>
                        </div>
                      )}
                      <button
                        onClick={() => handleMarkReady(order.id)}
                        className="w-full py-2.5 bg-emerald-500 hover:bg-emerald-600 font-extrabold text-white text-xs rounded-xl transition-all shadow-lg"
                      >
                        Mark Ready for Dispatch ✓
                      </button>
                    </>
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
