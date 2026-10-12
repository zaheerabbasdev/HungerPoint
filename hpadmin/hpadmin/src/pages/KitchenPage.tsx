// ============================================================
// HungerPoint Web App — Kitchen Display Unit (KDU)
// Route: /kitchen
//
// Fully separate from the Admin console: its own login screen, its own
// browser session (hp_kitchen_* keys) and KITCHEN_STAFF accounts only.
// Admin / Branch Manager cannot sign in here.
// ============================================================

import React, { useState, useEffect, useRef } from 'react';
import { fetchApi, KITCHEN_SESSION } from '../lib/api';
import { getKitchenSocket, resetKitchenSocket } from '../lib/socket';

const kitchenFetch = (endpoint: string, options: RequestInit = {}) =>
  fetchApi(endpoint, options, KITCHEN_SESSION);

function clearKitchenSession() {
  localStorage.removeItem(KITCHEN_SESSION.access);
  localStorage.removeItem(KITCHEN_SESSION.refresh);
  localStorage.removeItem(KITCHEN_SESSION.user);
}

// The cook can type any whole number of minutes in this range.
const MIN_PREP = 1;
const MAX_PREP = 180;
const DEFAULT_PREP = '15';
const QUICK_MINUTES = [5, 10, 15, 20, 30, 45];
const SOUND_KEY = 'hp_kitchen_sound';

const parseMinutes = (value: string): number | null => {
  if (!/^\d+$/.test(value)) return null;
  const n = parseInt(value, 10);
  return n >= MIN_PREP && n <= MAX_PREP ? n : null;
};

// Two short beeps for a new ticket. Browsers only allow sound after a click (the login counts).
function beep() {
  try {
    const Ctx = window.AudioContext || (window as any).webkitAudioContext;
    const ctx = new Ctx();
    [0, 0.25].forEach((delay) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.frequency.value = 880;
      gain.gain.value = 0.15;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(ctx.currentTime + delay);
      osc.stop(ctx.currentTime + delay + 0.15);
    });
    setTimeout(() => ctx.close(), 800);
  } catch {
    /* sound is optional */
  }
}

const minutesSince = (iso: string | null | undefined, now: number): number =>
  iso ? Math.max(0, Math.floor((now - new Date(iso).getTime()) / 60000)) : 0;

function orderTypeLabel(order: any): { icon: string; text: string; tone: string } {
  if (order.type === 'DINE_IN') {
    return { icon: '🍽️', text: order.table?.number ? `Table ${order.table.number}` : 'Dine-in', tone: 'bg-sky-500/15 text-sky-300 border-sky-500/30' };
  }
  if (order.type === 'PICKUP') return { icon: '🥡', text: 'Pickup', tone: 'bg-violet-500/15 text-violet-300 border-violet-500/30' };
  return { icon: '🛵', text: 'Delivery', tone: 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30' };
}

export default function KitchenDisplayPage() {
  const [kitchenUser, setKitchenUser] = useState<any>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [queue, setQueue] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [now, setNow] = useState(Date.now());
  const [connected, setConnected] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [soundOn, setSoundOn] = useState<boolean>(() => {
    try {
      return localStorage.getItem(SOUND_KEY) !== 'off';
    } catch {
      return true;
    }
  });
  // What the cook has typed for each ticket (kept as text so it can be empty while typing).
  const [prepInput, setPrepInput] = useState<Record<string, string>>({});

  const seenIds = useRef<Set<string> | null>(null);
  const soundRef = useRef(soundOn);
  soundRef.current = soundOn;

  // Login form
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [loginError, setLoginError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const showError = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 4000);
  };

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
        if (res.success) {
          const orders: any[] = res.data;
          // Beep when a ticket we have not seen yet arrives (never on the first load).
          const known = seenIds.current;
          if (known && soundRef.current && orders.some((o) => o.status === 'CONFIRMED' && !known.has(o.id))) beep();
          seenIds.current = new Set(orders.map((o) => o.id));
          setQueue(orders);
        }
      } catch (err) {
        console.error('Failed to load kitchen queue:', err);
      } finally {
        setLoading(false);
      }
    }
    loadKitchenQueue();

    const socket = getKitchenSocket();
    const handleQueueEvent = () => loadKitchenQueue();
    const onConnect = () => setConnected(true);
    const onDisconnect = () => setConnected(false);
    setConnected(socket.connected);
    socket.on('order.created', handleQueueEvent);
    socket.on('kitchen.queue_updated', handleQueueEvent);
    socket.on('connect', onConnect);
    socket.on('disconnect', onDisconnect);

    // Fallback safety-net refresh in case a socket event is missed/disconnected
    const interval = setInterval(loadKitchenQueue, 30000);
    const tick = setInterval(() => setNow(Date.now()), 10000);

    return () => {
      socket.off('order.created', handleQueueEvent);
      socket.off('kitchen.queue_updated', handleQueueEvent);
      socket.off('connect', onConnect);
      socket.off('disconnect', onDisconnect);
      clearInterval(interval);
      clearInterval(tick);
      seenIds.current = null;
    };
  }, [kitchenUser]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setLoginError('');
    try {
      const id = identifier.trim();
      const body = id.includes('@') ? { email: id, password } : { phone: id, password };

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

  const toggleSound = () => {
    const next = !soundOn;
    setSoundOn(next);
    try {
      localStorage.setItem(SOUND_KEY, next ? 'on' : 'off');
    } catch {
      /* ignore */
    }
    if (next) beep();
  };

  const minutesFor = (orderId: string): string => prepInput[orderId] ?? DEFAULT_PREP;
  const setMinutesFor = (orderId: string, value: string) =>
    setPrepInput((p) => ({ ...p, [orderId]: value.replace(/\D/g, '').slice(0, 3) }));
  const stepMinutes = (orderId: string, delta: number) => {
    const current = parseMinutes(minutesFor(orderId)) ?? parseInt(DEFAULT_PREP, 10);
    setMinutesFor(orderId, String(Math.min(MAX_PREP, Math.max(MIN_PREP, current + delta))));
  };

  const handleStartPrepare = async (orderId: string) => {
    const minutes = parseMinutes(minutesFor(orderId));
    if (minutes === null) {
      showError(`Enter the preparation time as a whole number of minutes (${MIN_PREP}-${MAX_PREP}).`);
      return;
    }
    setBusyId(orderId);
    try {
      const res = await kitchenFetch(`/kitchen/orders/${orderId}/prepare`, {
        method: 'PATCH',
        body: JSON.stringify({ estimatedPrepTime: minutes }),
      });
      if (res.success) {
        setQueue((prev) => prev.map((o) => (o.id === orderId ? { ...o, ...res.data } : o)));
      }
    } catch (e: any) {
      showError(e.message || 'Error updating order');
    } finally {
      setBusyId(null);
    }
  };

  const handleExtend = async (orderId: string, extraMinutes: number) => {
    setBusyId(orderId);
    try {
      const res = await kitchenFetch(`/kitchen/orders/${orderId}/extend`, {
        method: 'PATCH',
        body: JSON.stringify({ extraMinutes }),
      });
      if (res.success) {
        setQueue((prev) => prev.map((o) => (o.id === orderId ? { ...o, ...res.data } : o)));
      }
    } catch (e: any) {
      showError(e.message || 'Error updating order');
    } finally {
      setBusyId(null);
    }
  };

  const handleMarkReady = async (orderId: string) => {
    setBusyId(orderId);
    try {
      const res = await kitchenFetch(`/kitchen/orders/${orderId}/ready`, { method: 'PATCH' });
      if (res.success) {
        setQueue((prev) => prev.filter((o) => o.id !== orderId));
      }
    } catch (e: any) {
      showError(e.message || 'Error updating order');
    } finally {
      setBusyId(null);
    }
  };

  // Minutes left until the food is due (cooking start + prep time).
  const dueInMinutes = (order: any): number | null => {
    if (!order.acceptedAt || !order.estimatedPrepTime) return null;
    const due = new Date(order.acceptedAt).getTime() + order.estimatedPrepTime * 60_000;
    return Math.ceil((due - now) / 60_000);
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
      <div className="min-h-screen bg-gradient-to-br from-stone-950 via-stone-900 to-amber-950/40 text-stone-100 flex items-center justify-center p-6">
        <form
          onSubmit={handleLogin}
          className="w-full max-w-sm bg-stone-900/90 backdrop-blur border border-stone-800 rounded-3xl p-8 space-y-5 shadow-2xl shadow-black/50"
        >
          <div className="text-center space-y-2">
            <div className="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center text-3xl shadow-lg shadow-orange-500/30">
              🍳
            </div>
            <h1 className="text-2xl font-black text-amber-400">Kitchen Login</h1>
            <p className="text-xs text-stone-500">Kitchen Display Unit · staff only</p>
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
            className="w-full px-4 py-3 bg-stone-950 border border-stone-800 rounded-xl text-sm focus:outline-none focus:border-amber-500"
          />
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
            autoComplete="current-password"
            className="w-full px-4 py-3 bg-stone-950 border border-stone-800 rounded-xl text-sm focus:outline-none focus:border-amber-500"
          />
          <button
            type="submit"
            disabled={submitting}
            className="w-full py-3 bg-gradient-to-r from-amber-400 to-orange-500 hover:from-amber-300 hover:to-orange-400 disabled:opacity-50 font-extrabold text-stone-950 text-sm rounded-xl transition-all"
          >
            {submitting ? 'Signing in...' : 'Sign in to Kitchen'}
          </button>
        </form>
      </div>
    );
  }

  const newOrders = queue.filter((o) => o.status !== 'PREPARING');
  const cooking = queue.filter((o) => o.status === 'PREPARING');
  const lateCount = cooking.filter((o) => (dueInMinutes(o) ?? 1) < 0).length;

  const itemsList = (order: any, compact = false) => (
    <div className={compact ? 'space-y-1.5' : 'space-y-2.5'}>
      {order.items?.map((item: any) => (
        <div key={item.id} className="flex gap-3 items-start">
          <span className="shrink-0 min-w-8 h-8 px-2 rounded-lg bg-amber-500/15 border border-amber-500/30 text-amber-400 text-sm font-black flex items-center justify-center">
            {item.quantity}×
          </span>
          <div className="min-w-0">
            <p className="text-sm font-bold text-stone-100 leading-tight">
              {item.product?.name}
              {item.variant?.name && <span className="text-amber-400 font-semibold"> · {item.variant.name}</span>}
            </p>
            {item.addons?.length > 0 && (
              <p className="text-[11px] text-stone-400 mt-0.5">+ {item.addons.map((a: any) => a.addonName).join(', ')}</p>
            )}
            {item.notes && <p className="text-[11px] text-yellow-300/90 italic mt-0.5">“{item.notes}”</p>}
          </div>
        </div>
      ))}
    </div>
  );

  const orderNote = (order: any) =>
    order.notes ? (
      <div className="text-xs text-yellow-200 bg-yellow-500/10 border border-yellow-500/30 rounded-xl px-3 py-2">
        <span className="font-black uppercase tracking-wider text-[10px] text-yellow-400 block">Order note</span>
        {order.notes}
      </div>
    ) : null;

  const cardHeader = (order: any, waitLabel?: React.ReactNode) => {
    const t = orderTypeLabel(order);
    return (
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="font-mono font-black text-lg text-amber-400 leading-tight">{order.orderNumber}</p>
          <span className={`inline-flex items-center gap-1 mt-1.5 px-2 py-0.5 rounded-full border text-[11px] font-bold ${t.tone}`}>
            <span>{t.icon}</span> {t.text}
          </span>
        </div>
        {waitLabel}
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-stone-950 to-stone-900 text-stone-100">
      {toast && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-50 px-4 py-2.5 bg-red-500/90 text-white text-sm font-bold rounded-xl shadow-xl">
          {toast}
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6 space-y-8">
        {/* Header */}
        <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-5 border-b border-stone-800">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center text-2xl shadow-lg shadow-orange-500/20">
              🍳
            </div>
            <div>
              <h1 className="text-2xl font-black text-stone-100 leading-tight">Kitchen Display</h1>
              <p className="text-xs text-stone-500 flex items-center gap-2">
                <span>Signed in as {kitchenUser.name}</span>
                <span className="flex items-center gap-1">
                  <span className={`w-2 h-2 rounded-full ${connected ? 'bg-emerald-400' : 'bg-red-400'}`} />
                  {connected ? 'Live' : 'Reconnecting…'}
                </span>
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="px-4 py-2 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-center min-w-20">
              <p className="text-2xl font-black text-amber-400 leading-none">{newOrders.length}</p>
              <p className="text-[10px] font-bold uppercase tracking-wider text-stone-400 mt-1">New</p>
            </div>
            <div className="px-4 py-2 rounded-2xl bg-orange-500/10 border border-orange-500/30 text-center min-w-20">
              <p className="text-2xl font-black text-orange-400 leading-none">{cooking.length}</p>
              <p className="text-[10px] font-bold uppercase tracking-wider text-stone-400 mt-1">Cooking</p>
            </div>
            <div
              className={`px-4 py-2 rounded-2xl border text-center min-w-20 ${
                lateCount > 0 ? 'bg-red-500/10 border-red-500/40' : 'bg-stone-800/60 border-stone-700'
              }`}
            >
              <p className={`text-2xl font-black leading-none ${lateCount > 0 ? 'text-red-400' : 'text-stone-500'}`}>{lateCount}</p>
              <p className="text-[10px] font-bold uppercase tracking-wider text-stone-400 mt-1">Late</p>
            </div>
            <button
              onClick={toggleSound}
              title={soundOn ? 'Sound on: beeps for new orders' : 'Sound off'}
              className="w-11 h-11 rounded-2xl bg-stone-800 hover:bg-stone-700 text-lg transition-colors"
            >
              {soundOn ? '🔔' : '🔕'}
            </button>
            <button
              onClick={handleLogout}
              className="px-4 py-2.5 bg-stone-800 hover:bg-stone-700 text-stone-300 text-xs font-bold rounded-2xl transition-colors"
            >
              Log out
            </button>
          </div>
        </header>

        {loading ? (
          <div className="text-center py-24 text-stone-500">Loading kitchen tickets...</div>
        ) : queue.length === 0 ? (
          <div className="text-center py-24 bg-stone-900/40 rounded-3xl border border-stone-800 text-stone-500 space-y-2">
            <span className="text-5xl block">✨</span>
            <p className="text-lg font-bold text-stone-300">Kitchen queue is clear!</p>
            <p className="text-xs">New orders appear here automatically.</p>
          </div>
        ) : (
          <>
            {/* ───────── NEW ORDERS ───────── */}
            <section className="space-y-4">
              <h2 className="text-sm font-black uppercase tracking-widest text-amber-400 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" /> New orders
                <span className="text-stone-500 font-bold">({newOrders.length})</span>
              </h2>
              {newOrders.length === 0 ? (
                <p className="text-xs text-stone-600 px-1">No new orders waiting.</p>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                  {newOrders.map((order) => {
                    const waited = minutesSince(order.confirmedAt ?? order.createdAt, now);
                    const waitTone =
                      waited >= 20 ? 'bg-red-500/15 text-red-300 border-red-500/40'
                      : waited >= 10 ? 'bg-amber-500/15 text-amber-300 border-amber-500/40'
                      : 'bg-stone-800 text-stone-300 border-stone-700';
                    const typed = minutesFor(order.id);
                    const minutes = parseMinutes(typed);
                    const invalid = minutes === null;

                    return (
                      <div
                        key={order.id}
                        className="rounded-3xl bg-stone-900 border border-stone-800 border-t-4 border-t-amber-500 p-5 space-y-4 shadow-xl shadow-black/30"
                      >
                        {cardHeader(
                          order,
                          <span className={`px-2.5 py-1 rounded-full border text-[11px] font-black whitespace-nowrap ${waitTone}`}>
                            ⏱ {waited} min ago
                          </span>,
                        )}

                        {itemsList(order)}
                        {orderNote(order)}

                        <div className="pt-4 border-t border-stone-800 space-y-3">
                          <p className="text-[10px] font-black uppercase tracking-wider text-stone-500">Preparation time</p>

                          {/* Free entry: any whole number of minutes */}
                          <div className="flex items-stretch gap-2">
                            <button
                              type="button"
                              onClick={() => stepMinutes(order.id, -1)}
                              className="w-11 rounded-xl bg-stone-800 hover:bg-stone-700 text-xl font-black text-stone-200"
                              aria-label="One minute less"
                            >
                              −
                            </button>
                            <div className="relative flex-1">
                              <input
                                type="text"
                                inputMode="numeric"
                                value={typed}
                                onChange={(e) => setMinutesFor(order.id, e.target.value)}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter' && !invalid && busyId !== order.id) handleStartPrepare(order.id);
                                }}
                                placeholder="e.g. 12"
                                aria-label="Preparation time in minutes"
                                className={`w-full h-12 text-center text-2xl font-black rounded-xl bg-stone-950 border-2 outline-none transition-colors ${
                                  invalid ? 'border-red-500/60 text-red-300' : 'border-stone-700 focus:border-amber-500 text-stone-100'
                                }`}
                              />
                              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-500 pointer-events-none">
                                min
                              </span>
                            </div>
                            <button
                              type="button"
                              onClick={() => stepMinutes(order.id, 1)}
                              className="w-11 rounded-xl bg-stone-800 hover:bg-stone-700 text-xl font-black text-stone-200"
                              aria-label="One minute more"
                            >
                              +
                            </button>
                          </div>

                          <div className="flex flex-wrap gap-1.5">
                            {QUICK_MINUTES.map((m) => (
                              <button
                                key={m}
                                type="button"
                                onClick={() => setMinutesFor(order.id, String(m))}
                                className={`px-3 py-1 rounded-lg text-xs font-black border transition-all ${
                                  minutes === m
                                    ? 'bg-amber-500 text-stone-950 border-amber-500'
                                    : 'bg-stone-950 text-stone-400 border-stone-700 hover:border-amber-500 hover:text-amber-300'
                                }`}
                              >
                                {m}
                              </button>
                            ))}
                          </div>

                          {invalid && (
                            <p className="text-[11px] text-red-400 font-bold">
                              Enter a whole number from {MIN_PREP} to {MAX_PREP} minutes.
                            </p>
                          )}

                          <button
                            onClick={() => handleStartPrepare(order.id)}
                            disabled={invalid || busyId === order.id}
                            className="w-full py-3 rounded-xl bg-gradient-to-r from-amber-400 to-orange-500 hover:from-amber-300 hover:to-orange-400 disabled:from-stone-700 disabled:to-stone-700 disabled:text-stone-500 font-extrabold text-stone-950 text-sm transition-all"
                          >
                            {busyId === order.id ? 'Starting…' : invalid ? 'Enter preparation time' : `Start Cooking · ${minutes} min 🔥`}
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </section>

            {/* ───────── COOKING NOW ───────── */}
            <section className="space-y-4">
              <h2 className="text-sm font-black uppercase tracking-widest text-orange-400 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-orange-400" /> Cooking now
                <span className="text-stone-500 font-bold">({cooking.length})</span>
              </h2>
              {cooking.length === 0 ? (
                <p className="text-xs text-stone-600 px-1">Nothing is cooking right now.</p>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                  {cooking.map((order) => {
                    const left = dueInMinutes(order);
                    const late = left !== null && left < 0;
                    const total = order.estimatedPrepTime || 0;
                    const elapsed = minutesSince(order.acceptedAt, now);
                    const progress = total > 0 ? Math.min(100, Math.round((elapsed / total) * 100)) : 0;
                    const soon = left !== null && left >= 0 && left <= 2;
                    const accent = late ? 'border-t-red-500' : soon ? 'border-t-amber-400' : 'border-t-emerald-500';
                    const barTone = late ? 'bg-red-500' : soon ? 'bg-amber-400' : 'bg-emerald-500';

                    return (
                      <div
                        key={order.id}
                        className={`rounded-3xl bg-stone-900 border border-stone-800 border-t-4 ${accent} p-5 space-y-4 shadow-xl shadow-black/30 ${
                          late ? 'ring-1 ring-red-500/40' : ''
                        }`}
                      >
                        {cardHeader(
                          order,
                          <div className="text-right">
                            <p className={`text-3xl font-black leading-none ${late ? 'text-red-400' : soon ? 'text-amber-400' : 'text-emerald-400'}`}>
                              {left === null ? '—' : late ? `+${Math.abs(left)}` : left}
                              <span className="text-xs font-bold ml-1">min</span>
                            </p>
                            <p className="text-[10px] font-bold uppercase tracking-wider text-stone-500 mt-1">
                              {left === null ? 'no time set' : late ? 'running late' : 'left'}
                            </p>
                          </div>,
                        )}

                        {/* progress */}
                        <div>
                          <div className="h-2 rounded-full bg-stone-800 overflow-hidden">
                            <div className={`h-full rounded-full transition-all ${barTone}`} style={{ width: `${late ? 100 : progress}%` }} />
                          </div>
                          <p className="text-[10px] text-stone-500 mt-1">
                            {elapsed} of {total} min · started {elapsed} min ago
                          </p>
                        </div>

                        {itemsList(order, true)}
                        {orderNote(order)}

                        <div className="pt-4 border-t border-stone-800 space-y-3">
                          <div className="flex items-center gap-2">
                            <span className="text-[10px] font-black uppercase tracking-wider text-stone-500 mr-auto">Need more time?</span>
                            {[5, 10].map((m) => (
                              <button
                                key={m}
                                onClick={() => handleExtend(order.id, m)}
                                disabled={busyId === order.id}
                                className="px-3 py-1.5 rounded-lg bg-stone-800 hover:bg-stone-700 disabled:opacity-50 text-stone-200 text-xs font-black"
                              >
                                +{m} min
                              </button>
                            ))}
                          </div>
                          <button
                            onClick={() => handleMarkReady(order.id)}
                            disabled={busyId === order.id}
                            className="w-full py-3 rounded-xl bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-400 hover:to-green-500 disabled:opacity-60 font-extrabold text-white text-sm shadow-lg shadow-emerald-900/40 transition-all"
                          >
                            {busyId === order.id ? 'Updating…' : 'Mark Ready ✓'}
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </section>
          </>
        )}
      </div>
    </div>
  );
}
