// ============================================================
// HungerPoint Web App — Reports & Analytics
// Route: /reports
// ============================================================

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { Link, useNavigate } from 'react-router';
import { fetchApi } from '../lib/api';
import { useBranch } from '../context/BranchContext';

const REPORTS_ALLOWED_ROLES = ['ADMIN', 'BRANCH_MANAGER'];

type RangePreset = 'today' | 'week' | 'month' | 'custom' | 'all';

const RANGE_OPTIONS: { key: RangePreset; label: string }[] = [
  { key: 'today', label: 'Today' },
  { key: 'week', label: 'Weekly' },
  { key: 'month', label: 'Monthly' },
  { key: 'custom', label: 'Custom' },
  { key: 'all', label: 'All Time' },
];

const PAGE_SIZE_OPTIONS = [10, 25, 50];

const STATUS_STYLES: Record<string, string> = {
  PENDING: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
  CONFIRMED: 'bg-sky-500/15 text-sky-400 border-sky-500/30',
  PREPARING: 'bg-orange-500/15 text-orange-400 border-orange-500/30',
  READY: 'bg-violet-500/15 text-violet-400 border-violet-500/30',
  OUT_FOR_DELIVERY: 'bg-indigo-500/15 text-indigo-400 border-indigo-500/30',
  DELIVERED: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  COMPLETED: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  CANCELLED: 'bg-red-500/15 text-red-400 border-red-500/30',
  REJECTED: 'bg-red-500/15 text-red-400 border-red-500/30',
};

const startOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
const endOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
const daysAgo = (n: number) => {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
};
const toInputDate = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const fromInputDate = (s: string) => {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, m - 1, d);
};

const formatPKR = (n: number) => `PKR ${Math.round(n).toLocaleString('en-PK')}`;
const formatDateTime = (iso: string) =>
  new Date(iso).toLocaleString('en-PK', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
const formatRangeLabel = (from?: Date, to?: Date) => {
  if (!from && !to) return 'All time';
  const fmt = (d: Date) => d.toLocaleDateString('en-PK', { day: '2-digit', month: 'short', year: 'numeric' });
  if (from && to && toInputDate(from) === toInputDate(to)) return fmt(from);
  return `${from ? fmt(from) : '…'} – ${to ? fmt(to) : '…'}`;
};

// Page list with ellipses, e.g. [1, '…', 4, 5, 6, '…', 12]
const buildPageList = (current: number, total: number): (number | '…')[] => {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const pages: (number | '…')[] = [1];
  const start = Math.max(2, current - 1);
  const end = Math.min(total - 1, current + 1);
  if (start > 2) pages.push('…');
  for (let p = start; p <= end; p++) pages.push(p);
  if (end < total - 1) pages.push('…');
  pages.push(total);
  return pages;
};

export default function ReportsPage() {
  const navigate = useNavigate();
  const { branches } = useBranch();

  const [currentUser, setCurrentUser] = useState<any>(null);
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [branchFilter, setBranchFilter] = useState('');
  const [preset, setPreset] = useState<RangePreset>('today');
  const [customFrom, setCustomFrom] = useState(toInputDate(daysAgo(6)));
  const [customTo, setCustomTo] = useState(toInputDate(new Date()));
  const [appliedCustom, setAppliedCustom] = useState<{ from: string; to: string } | null>(null);
  const [customError, setCustomError] = useState('');

  const [overview, setOverview] = useState<any>(null);
  const [statusBreakdown, setStatusBreakdown] = useState<any[]>([]);
  const [topProducts, setTopProducts] = useState<any[]>([]);
  const [sourceBreakdown, setSourceBreakdown] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const [orders, setOrders] = useState<any[]>([]);
  const [ordersTotal, setOrdersTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [ordersLoading, setOrdersLoading] = useState(true);

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
      navigate('/admin', { replace: true });
      return;
    }
    setCurrentUser(user);
    setAuthorized(true);
    setCheckingAuth(false);
  }, [navigate]);

  const range = useMemo((): { from?: Date; to?: Date } => {
    const now = new Date();
    switch (preset) {
      case 'today':
        return { from: startOfDay(now), to: endOfDay(now) };
      case 'week':
        return { from: startOfDay(daysAgo(6)), to: endOfDay(now) };
      case 'month':
        return { from: startOfDay(daysAgo(29)), to: endOfDay(now) };
      case 'custom':
        return appliedCustom
          ? { from: startOfDay(fromInputDate(appliedCustom.from)), to: endOfDay(fromInputDate(appliedCustom.to)) }
          : {};
      default:
        return {};
    }
  }, [preset, appliedCustom]);

  const filterQuery = useMemo(() => {
    const params = new URLSearchParams();
    if (branchFilter) params.set('branchId', branchFilter);
    if (range.from) params.set('from', range.from.toISOString());
    if (range.to) params.set('to', range.to.toISOString());
    return params.toString();
  }, [branchFilter, range]);

  // Waiting on the user to pick and apply custom dates — don't fire a query yet.
  const awaitingCustom = preset === 'custom' && !appliedCustom;

  const loadReports = useCallback(async () => {
    setLoading(true);
    try {
      const qs = filterQuery ? `?${filterQuery}` : '';
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
  }, [filterQuery]);

  const ordersRequestId = useRef(0);

  const loadOrders = useCallback(async () => {
    const requestId = ++ordersRequestId.current;
    setOrdersLoading(true);
    try {
      const params = new URLSearchParams(filterQuery);
      params.set('page', String(page));
      params.set('pageSize', String(pageSize));
      const res = await fetchApi(`/reports/orders?${params.toString()}`);
      if (requestId !== ordersRequestId.current) return;
      if (res.success) {
        setOrders(res.data.items);
        setOrdersTotal(res.data.total);
        setTotalPages(res.data.totalPages);
      }
    } catch (err) {
      console.error('Failed to load orders:', err);
    } finally {
      if (requestId === ordersRequestId.current) setOrdersLoading(false);
    }
  }, [filterQuery, page, pageSize]);

  useEffect(() => {
    if (authorized && !awaitingCustom) loadReports();
  }, [authorized, awaitingCustom, loadReports]);

  useEffect(() => {
    if (authorized && !awaitingCustom) loadOrders();
  }, [authorized, awaitingCustom, loadOrders]);

  // Any filter change invalidates the current page position.
  useEffect(() => {
    setPage(1);
  }, [filterQuery, pageSize]);

  const selectPreset = (key: RangePreset) => {
    setCustomError('');
    setPreset(key);
  };

  const applyCustomRange = () => {
    if (!customFrom || !customTo) {
      setCustomError('Pick both a start and an end date.');
      return;
    }
    if (customFrom > customTo) {
      setCustomError('Start date must be on or before the end date.');
      return;
    }
    setCustomError('');
    setAppliedCustom({ from: customFrom, to: customTo });
  };

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
  const statusTotal = statusBreakdown.reduce((sum, s) => sum + s.count, 0);
  const showingFrom = ordersTotal === 0 ? 0 : (page - 1) * pageSize + 1;
  const showingTo = Math.min(page * pageSize, ordersTotal);
  const statsLoading = loading || awaitingCustom;

  const statCards = [
    { label: 'Total Orders', value: overview?.totalOrders?.toLocaleString(), icon: '📦', accent: 'from-amber-500/20 to-orange-600/5', ring: 'border-amber-500/20' },
    { label: 'Revenue (Delivered)', value: overview ? formatPKR(overview.totalRevenue) : undefined, icon: '💰', accent: 'from-emerald-500/20 to-teal-600/5', ring: 'border-emerald-500/20' },
    { label: 'Avg. Order Value', value: overview ? formatPKR(overview.averageOrderValue ?? 0) : undefined, icon: '🧾', accent: 'from-sky-500/20 to-indigo-600/5', ring: 'border-sky-500/20' },
    { label: 'In Progress', value: overview?.pendingOrders?.toLocaleString(), icon: '⏳', accent: 'from-violet-500/20 to-fuchsia-600/5', ring: 'border-violet-500/20' },
    { label: 'Active Riders', value: overview?.activeRiders?.toLocaleString(), icon: '🛵', accent: 'from-orange-500/20 to-red-600/5', ring: 'border-orange-500/20', live: true },
    { label: 'Customers', value: overview?.totalCustomers?.toLocaleString(), icon: '👥', accent: 'from-stone-500/20 to-stone-700/5', ring: 'border-stone-600/40', live: true },
  ];

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100">
      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-4 sm:px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 flex-wrap">
          <div>
            <Link to="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>📊</span> Reports & Analytics</h1>
          </div>
          <div className="flex items-center gap-2">
            {currentUser?.role !== 'BRANCH_MANAGER' && (
              <select
                value={branchFilter}
                onChange={(e) => setBranchFilter(e.target.value)}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2 text-xs text-stone-200 outline-none focus:border-amber-500"
              >
                <option value="">All Branches</option>
                {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            )}
            <button
              onClick={() => { loadReports(); loadOrders(); }}
              disabled={awaitingCustom || loading}
              className="px-3 py-2 bg-stone-800 border border-stone-700 hover:border-amber-500/50 rounded-xl text-xs font-bold text-stone-300 disabled:opacity-50"
              title="Refresh"
            >
              ↻ Refresh
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-6 space-y-6">
        {/* Date range filter */}
        <div className="bg-stone-900 border border-stone-800 rounded-2xl p-4 space-y-3">
          <div className="flex items-center justify-between gap-3 flex-wrap">
            <div className="inline-flex flex-wrap gap-1 p-1 bg-stone-950 border border-stone-800 rounded-xl">
              {RANGE_OPTIONS.map((opt) => (
                <button
                  key={opt.key}
                  onClick={() => selectPreset(opt.key)}
                  className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    preset === opt.key
                      ? 'bg-gradient-to-r from-amber-500 to-orange-600 text-stone-950 shadow-lg shadow-orange-900/30'
                      : 'text-stone-400 hover:text-stone-100 hover:bg-stone-800'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
            <p className="text-xs text-stone-400">
              Showing: <span className="font-bold text-stone-200">{awaitingCustom ? 'Select a custom range' : formatRangeLabel(range.from, range.to)}</span>
            </p>
          </div>

          {preset === 'custom' && (
            <div className="flex items-end gap-3 flex-wrap pt-1">
              <label className="flex flex-col gap-1">
                <span className="text-[10px] font-bold text-stone-500 uppercase tracking-wide">From</span>
                <input
                  type="date"
                  value={customFrom}
                  max={customTo || undefined}
                  onChange={(e) => setCustomFrom(e.target.value)}
                  className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2 text-xs text-stone-100 outline-none focus:border-amber-500 [color-scheme:dark]"
                />
              </label>
              <label className="flex flex-col gap-1">
                <span className="text-[10px] font-bold text-stone-500 uppercase tracking-wide">To</span>
                <input
                  type="date"
                  value={customTo}
                  min={customFrom || undefined}
                  max={toInputDate(new Date())}
                  onChange={(e) => setCustomTo(e.target.value)}
                  className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-2 text-xs text-stone-100 outline-none focus:border-amber-500 [color-scheme:dark]"
                />
              </label>
              <button
                onClick={applyCustomRange}
                className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-stone-950 text-xs font-extrabold rounded-xl"
              >
                Apply
              </button>
              {customError && <p className="text-xs text-red-400 w-full">{customError}</p>}
            </div>
          )}
        </div>

        {/* Overview stats */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {statCards.map((s) => (
            <div key={s.label} className={`relative overflow-hidden bg-stone-900 border ${s.ring} rounded-2xl p-4`}>
              <div className={`absolute inset-0 bg-gradient-to-br ${s.accent} pointer-events-none`} />
              <div className="relative">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xl">{s.icon}</span>
                  {s.live && <span className="text-[9px] font-bold text-stone-500 uppercase tracking-wide">Live</span>}
                </div>
                {statsLoading ? (
                  <div className="h-6 w-20 bg-stone-800 rounded animate-pulse mb-1" />
                ) : (
                  <p className="text-lg font-black text-stone-100 truncate">{s.value ?? '—'}</p>
                )}
                <p className="text-[10px] text-stone-400 font-bold uppercase tracking-wide">{s.label}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Orders by status */}
          <div className="bg-stone-900 border border-stone-800 rounded-2xl p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-extrabold text-stone-100">Orders by Status</h2>
              <span className="text-[11px] text-stone-500">{statusTotal} total</span>
            </div>
            {statsLoading ? (
              <div className="space-y-3">{[0, 1, 2, 3].map((i) => <div key={i} className="h-6 bg-stone-800 rounded animate-pulse" />)}</div>
            ) : statusBreakdown.length === 0 ? (
              <p className="text-xs text-stone-500 text-center py-8">No orders in this period.</p>
            ) : (
              <div className="space-y-2.5">
                {statusBreakdown.map((s) => (
                  <div key={s.status}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="font-bold text-stone-300">{s.status.replace(/_/g, ' ')}</span>
                      <span className="text-stone-400">
                        {s.count} <span className="text-stone-600">· {Math.round((s.count / Math.max(1, statusTotal)) * 100)}%</span>
                      </span>
                    </div>
                    <div className="h-2 bg-stone-800 rounded-full overflow-hidden">
                      <div className="h-full bg-gradient-to-r from-amber-500 to-orange-600 rounded-full transition-all" style={{ width: `${(s.count / maxStatusCount) * 100}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Orders by source */}
          <div className="bg-stone-900 border border-stone-800 rounded-2xl p-5">
            <h2 className="text-sm font-extrabold text-stone-100 mb-4">Orders by Source</h2>
            {statsLoading ? (
              <div className="space-y-3">{[0, 1, 2].map((i) => <div key={i} className="h-6 bg-stone-800 rounded animate-pulse" />)}</div>
            ) : sourceBreakdown.length === 0 ? (
              <p className="text-xs text-stone-500 text-center py-8">No orders in this period.</p>
            ) : (
              <div className="space-y-2.5">
                {sourceBreakdown.map((s) => (
                  <div key={s.source}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="font-bold text-stone-300">{String(s.source).replace(/_/g, ' ')}</span>
                      <span className="text-stone-400">{s.count}</span>
                    </div>
                    <div className="h-2 bg-stone-800 rounded-full overflow-hidden">
                      <div className="h-full bg-gradient-to-r from-emerald-500 to-teal-600 rounded-full transition-all" style={{ width: `${(s.count / maxSourceCount) * 100}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Top products */}
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          <div className="p-4 border-b border-stone-800 flex items-center justify-between">
            <h2 className="text-sm font-extrabold text-stone-100">Top Selling Products</h2>
            <span className="text-[11px] text-stone-500">Top 10</span>
          </div>
          {statsLoading ? (
            <div className="p-4 space-y-2">{[0, 1, 2].map((i) => <div key={i} className="h-8 bg-stone-800 rounded animate-pulse" />)}</div>
          ) : topProducts.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No sales in this period.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs min-w-[480px]">
                <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                  <tr>
                    <th className="text-left px-4 py-2.5 font-bold w-10">#</th>
                    <th className="text-left px-4 py-2.5 font-bold">Product</th>
                    <th className="text-right px-4 py-2.5 font-bold">Units Sold</th>
                    <th className="text-right px-4 py-2.5 font-bold">Revenue</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-800">
                  {topProducts.map((p, idx) => (
                    <tr key={p.product?.id || idx} className="hover:bg-stone-800/30">
                      <td className="px-4 py-2.5 font-black text-stone-500">{idx + 1}</td>
                      <td className="px-4 py-2.5">
                        <div className="flex items-center gap-2.5">
                          {p.product?.image
                            ? <img src={p.product.image} alt="" className="w-8 h-8 rounded-lg object-cover" />
                            : <div className="w-8 h-8 rounded-lg bg-stone-800" />}
                          <span className="font-bold text-stone-100">{p.product?.name || 'Unknown product'}</span>
                        </div>
                      </td>
                      <td className="px-4 py-2.5 text-right text-stone-300">{p.quantitySold}</td>
                      <td className="px-4 py-2.5 text-right font-bold text-amber-400">{formatPKR(p.revenue)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Orders (paginated) */}
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          <div className="p-4 border-b border-stone-800">
            <h2 className="text-sm font-extrabold text-stone-100">Orders</h2>
            <p className="text-[11px] text-stone-500">{ordersTotal.toLocaleString()} order{ordersTotal === 1 ? '' : 's'} in this period</p>
          </div>

          {ordersLoading || awaitingCustom ? (
            <div className="p-4 space-y-2">{Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-8 bg-stone-800 rounded animate-pulse" />)}</div>
          ) : orders.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">No orders in this period.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs min-w-[760px]">
                <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                  <tr>
                    <th className="text-left px-4 py-2.5 font-bold">Order #</th>
                    <th className="text-left px-4 py-2.5 font-bold">Date</th>
                    <th className="text-left px-4 py-2.5 font-bold">Customer</th>
                    <th className="text-left px-4 py-2.5 font-bold">Branch</th>
                    <th className="text-left px-4 py-2.5 font-bold">Type</th>
                    <th className="text-left px-4 py-2.5 font-bold">Status</th>
                    <th className="text-right px-4 py-2.5 font-bold">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-800">
                  {orders.map((o: any) => (
                    <tr key={o.id} className="hover:bg-stone-800/30">
                      <td className="px-4 py-2.5 font-mono font-bold text-amber-400">{o.orderNumber}</td>
                      <td className="px-4 py-2.5 text-stone-400 whitespace-nowrap">{formatDateTime(o.createdAt)}</td>
                      <td className="px-4 py-2.5 text-stone-300">{o.customer?.user?.name || 'Walk-in'}</td>
                      <td className="px-4 py-2.5 text-stone-400">{o.branch?.name || '—'}</td>
                      <td className="px-4 py-2.5 text-stone-400">{String(o.type || '').replace(/_/g, ' ')}</td>
                      <td className="px-4 py-2.5">
                        <span className={`inline-block px-2 py-0.5 rounded-md border text-[10px] font-bold ${STATUS_STYLES[o.status] || 'bg-stone-800 text-stone-300 border-stone-700'}`}>
                          {String(o.status).replace(/_/g, ' ')}
                        </span>
                      </td>
                      <td className="px-4 py-2.5 text-right font-bold text-stone-100">{formatPKR(Number(o.total))}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {ordersTotal > 0 && !awaitingCustom && (
            <div className="px-4 py-3 border-t border-stone-800 flex items-center justify-between gap-3 flex-wrap">
              <p className="text-[11px] text-stone-500">
                Showing <span className="font-bold text-stone-300">{showingFrom}–{showingTo}</span> of{' '}
                <span className="font-bold text-stone-300">{ordersTotal.toLocaleString()}</span>
              </p>
              <div className="flex items-center gap-1 flex-wrap">
                <label className="flex items-center gap-2 text-[11px] text-stone-400 mr-2">
                  Rows per page
                  <select
                    value={pageSize}
                    onChange={(e) => setPageSize(Number(e.target.value))}
                    className="bg-stone-800 border border-stone-700 rounded-lg px-2 py-1.5 text-xs text-stone-200 outline-none focus:border-amber-500"
                  >
                    {PAGE_SIZE_OPTIONS.map((n) => <option key={n} value={n}>{n}</option>)}
                  </select>
                </label>
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1 || ordersLoading}
                  className="px-2.5 py-1.5 rounded-lg text-xs font-bold text-stone-300 bg-stone-800 hover:bg-stone-700 disabled:opacity-40 disabled:hover:bg-stone-800"
                >
                  ‹ Prev
                </button>
                {buildPageList(page, totalPages).map((p, i) =>
                  p === '…' ? (
                    <span key={`gap-${i}`} className="px-1.5 text-xs text-stone-600">…</span>
                  ) : (
                    <button
                      key={p}
                      onClick={() => setPage(p)}
                      disabled={ordersLoading}
                      className={`min-w-[30px] px-2 py-1.5 rounded-lg text-xs font-bold ${
                        p === page
                          ? 'bg-amber-500 text-stone-950'
                          : 'text-stone-400 bg-stone-800/50 hover:bg-stone-700 hover:text-stone-100'
                      }`}
                    >
                      {p}
                    </button>
                  )
                )}
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page >= totalPages || ordersLoading}
                  className="px-2.5 py-1.5 rounded-lg text-xs font-bold text-stone-300 bg-stone-800 hover:bg-stone-700 disabled:opacity-40 disabled:hover:bg-stone-800"
                >
                  Next ›
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
