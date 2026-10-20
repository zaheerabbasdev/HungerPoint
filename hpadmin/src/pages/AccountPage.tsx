// ============================================================
// HungerPoint Web App — Customer account area
// ============================================================
// Everything the mobile app's tabs and profile screens offer, for the website:
// orders (track + review), favourites, saved addresses, vouchers, loyalty points,
// notifications, branches and profile.

import { useCallback, useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router';
import { CustomerShell } from '../components/CustomerShell';
import { AddressForm, type SavedAddress } from '../components/AddressForm';
import { ProductModal } from '../components/ProductModal';
import { useAuth } from '../context/AuthContext';
import { useBranch } from '../context/BranchContext';
import { fetchApi, resolveImageUrl } from '../lib/api';
import { useFavorites } from '../lib/useFavorites';
import { toNumber } from '../lib/menu';

const TABS = [
  { key: 'orders', label: '🧾 My Orders' },
  { key: 'favorites', label: '❤️ Favourites' },
  { key: 'addresses', label: '📍 Addresses' },
  { key: 'vouchers', label: '🎟️ Vouchers' },
  { key: 'loyalty', label: '⭐ Loyalty' },
  { key: 'notifications', label: '🔔 Notifications' },
  { key: 'branches', label: '🏬 Branches' },
  { key: 'profile', label: '👤 Profile' },
] as const;
type TabKey = (typeof TABS)[number]['key'];

const card = 'bg-stone-900 border border-stone-800 rounded-2xl p-4';
const input = 'w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500';
const primaryBtn = 'px-4 py-2 bg-gradient-to-r from-amber-500 to-orange-600 text-white font-extrabold text-xs rounded-xl disabled:opacity-50';
const ghostBtn = 'px-3 py-1.5 bg-stone-800 hover:bg-stone-700 text-stone-200 font-bold text-xs rounded-lg';

const dateText = (d?: string) => (d ? new Date(d).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' }) : '');

const statusColour = (s: string) =>
  ['DELIVERED', 'COMPLETED'].includes(s)
    ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30'
    : ['CANCELLED', 'REJECTED', 'REFUNDED', 'PAYMENT_FAILED'].includes(s)
      ? 'bg-red-500/15 text-red-400 border-red-500/30'
      : 'bg-amber-500/15 text-amber-400 border-amber-500/30';

export default function AccountPage() {
  const { user } = useAuth();
  const [params, setParams] = useSearchParams();
  const tab = (TABS.find((t) => t.key === params.get('tab'))?.key ?? 'orders') as TabKey;

  return (
    <CustomerShell openAuth={!user}>
      {(openAuth) => (
        <main className="max-w-5xl mx-auto px-4 sm:px-6 py-8 space-y-6">
          <div>
            <Link to="/" className="text-xs text-amber-400 font-bold hover:underline">← Back to menu</Link>
            <h2 className="text-2xl font-black mt-1">My Account</h2>
          </div>

          {!user || user.role !== 'CUSTOMER' ? (
            <div className={`${card} text-center py-12 space-y-3`}>
              <p className="text-sm text-stone-300 font-bold">
                {user ? 'This area is for customer accounts.' : 'Sign in to see your orders, favourites, addresses and points.'}
              </p>
              {!user && <button onClick={openAuth} className={primaryBtn}>Sign In / Register</button>}
            </div>
          ) : (
            <>
              <div className="flex gap-2 overflow-x-auto pb-1">
                {TABS.map((t) => (
                  <button
                    key={t.key}
                    onClick={() => setParams({ tab: t.key })}
                    className={`px-4 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                      tab === t.key ? 'bg-amber-500 text-white shadow-md shadow-orange-500/20' : 'bg-stone-900 border border-stone-800 text-stone-400 hover:text-stone-100'
                    }`}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
              {tab === 'orders' && <OrdersTab />}
              {tab === 'favorites' && <FavoritesTab />}
              {tab === 'addresses' && <AddressesTab />}
              {tab === 'vouchers' && <VouchersTab />}
              {tab === 'loyalty' && <LoyaltyTab />}
              {tab === 'notifications' && <NotificationsTab />}
              {tab === 'branches' && <BranchesTab />}
              {tab === 'profile' && <ProfileTab />}
            </>
          )}
        </main>
      )}
    </CustomerShell>
  );
}

// ─── Orders ──────────────────────────────────────────────────
function OrdersTab() {
  const [orders, setOrders] = useState<any[] | null>(null);
  const [reviewed, setReviewed] = useState<Set<string>>(new Set());
  const [reviewing, setReviewing] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const [o, r] = await Promise.all([fetchApi('/orders?limit=50'), fetchApi('/reviews/mine').catch(() => null)]);
      setOrders(o.orders || o.data || []);
      setReviewed(new Set(((r?.data as any[]) || []).map((x) => x.orderId)));
    } catch {
      setOrders([]);
    }
  }, []);
  useEffect(() => {
    load();
  }, [load]);

  if (!orders) return <Loading />;
  if (orders.length === 0) return <Empty icon="🧾" text="You haven't placed any orders yet." />;

  return (
    <div className="space-y-3">
      {orders.map((o) => {
        const done = ['DELIVERED', 'COMPLETED'].includes(o.status);
        return (
          <div key={o.id} className={`${card} space-y-3`}>
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div>
                <p className="font-mono font-black text-amber-400">{o.orderNumber}</p>
                <p className="text-[11px] text-stone-500">
                  {dateText(o.createdAt)} · {o.type === 'PICKUP' ? 'Pickup' : o.type === 'DINE_IN' ? 'Dine-in' : 'Delivery'} · {o.branch?.name}
                </p>
              </div>
              <div className="text-right">
                <span className={`inline-block px-2.5 py-0.5 rounded-full border text-[10px] font-black uppercase ${statusColour(o.status)}`}>{o.status.replace(/_/g, ' ')}</span>
                <p className="text-sm font-black text-stone-100 mt-1">PKR {toNumber(o.total).toFixed(0)}</p>
              </div>
            </div>
            <ul className="text-xs text-stone-400 space-y-0.5">
              {(o.items || []).map((it: any) => (
                <li key={it.id}>
                  {it.quantity}× {it.product?.name}
                  {it.variant?.name ? ` (${it.variant.name})` : ''}
                  {it.addons?.length ? ` + ${it.addons.map((a: any) => a.addonName).join(', ')}` : ''}
                </li>
              ))}
            </ul>
            <div className="flex flex-wrap gap-2">
              <Link to={`/orders/${o.id}`} className={primaryBtn}>Track Order</Link>
              {done && !reviewed.has(o.id) && (
                <button onClick={() => setReviewing(reviewing === o.id ? null : o.id)} className={ghostBtn}>⭐ Rate this order</button>
              )}
              {done && reviewed.has(o.id) && <span className="text-[11px] text-emerald-400 font-bold self-center">✓ Reviewed</span>}
            </div>
            {reviewing === o.id && (
              <ReviewForm
                orderId={o.id}
                onDone={() => {
                  setReviewing(null);
                  load();
                }}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

function ReviewForm({ orderId, onDone }: { orderId: string; onDone: () => void }) {
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const submit = async () => {
    if (!rating) return setError('Please choose a star rating.');
    setSaving(true);
    try {
      const res = await fetchApi('/reviews', { method: 'POST', body: JSON.stringify({ orderId, rating, comment: comment.trim() || undefined }) });
      if (res.success) onDone();
      else setError(res.message || 'Could not send your review.');
    } catch (e: any) {
      setError(e.message || 'Could not send your review.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="bg-stone-950 border border-stone-800 rounded-xl p-3 space-y-2">
      <div className="flex gap-1 text-2xl">
        {[1, 2, 3, 4, 5].map((n) => (
          <button key={n} onClick={() => setRating(n)} aria-label={`${n} star${n > 1 ? 's' : ''}`} className={n <= rating ? 'text-amber-400' : 'text-stone-700'}>
            ★
          </button>
        ))}
      </div>
      <textarea value={comment} onChange={(e) => setComment(e.target.value)} rows={2} placeholder="Tell us about your meal (optional)" className={`${input} resize-none`} />
      {error && <p className="text-xs text-red-400 font-semibold">{error}</p>}
      <button onClick={submit} disabled={saving} className={primaryBtn}>{saving ? 'Sending…' : 'Submit review'}</button>
    </div>
  );
}

// ─── Favourites ──────────────────────────────────────────────
function FavoritesTab() {
  const { favorites, toggle } = useFavorites();
  const [product, setProduct] = useState<any | null>(null);

  if (favorites.length === 0) return <Empty icon="❤️" text="Tap the heart on any dish to save it here." />;
  return (
    <>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {favorites.map((p) => (
          <div key={p.id} className={`${card} flex gap-3`}>
            <div className="w-20 h-20 rounded-xl bg-stone-800 overflow-hidden shrink-0">
              {p.image && <img src={resolveImageUrl(p.image)} alt={p.name} className="w-full h-full object-cover" />}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-black text-sm truncate">{p.name}</p>
              <p className="text-xs text-amber-400 font-bold">PKR {toNumber(p.basePrice)}</p>
              <div className="flex gap-2 mt-2">
                <button onClick={() => setProduct(p)} className={primaryBtn}>Add</button>
                <button onClick={() => toggle(p)} className={ghostBtn}>Remove</button>
              </div>
            </div>
          </div>
        ))}
      </div>
      <ProductModal product={product} onClose={() => setProduct(null)} />
    </>
  );
}

// ─── Addresses ───────────────────────────────────────────────
function AddressesTab() {
  const [list, setList] = useState<SavedAddress[] | null>(null);
  const [editing, setEditing] = useState<SavedAddress | 'new' | null>(null);

  const load = useCallback(async () => {
    try {
      const res = await fetchApi('/customers/addresses');
      setList(res.data || []);
    } catch {
      setList([]);
    }
  }, []);
  useEffect(() => {
    load();
  }, [load]);

  const remove = async (a: SavedAddress) => {
    if (!window.confirm('Delete this address?')) return;
    await fetchApi(`/customers/addresses/${a.id}`, { method: 'DELETE' }).catch(() => {});
    load();
  };

  if (!list) return <Loading />;
  if (editing) {
    return (
      <div className={card}>
        <AddressForm
          existing={editing === 'new' ? null : editing}
          onCancel={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            load();
          }}
        />
      </div>
    );
  }
  return (
    <div className="space-y-3">
      {list.length === 0 && <Empty icon="📍" text="No saved addresses yet." />}
      {list.map((a) => (
        <div key={a.id} className={`${card} flex items-start justify-between gap-3`}>
          <div>
            <p className="font-black text-sm">
              {a.label === 'OTHER' ? a.customName || 'Other' : a.label === 'HOME' ? '🏠 Home' : '💼 Work'}
              {a.isDefault && <span className="ml-2 text-[10px] text-emerald-400 font-bold">DEFAULT</span>}
            </p>
            <p className="text-xs text-stone-400 mt-1">{a.address}</p>
            <p className="text-[11px] text-stone-600">{[a.area, a.city].filter(Boolean).join(', ')}</p>
          </div>
          <div className="flex gap-2 shrink-0">
            <button onClick={() => setEditing(a)} className={ghostBtn}>Edit</button>
            <button onClick={() => remove(a)} className={`${ghostBtn} text-red-400`}>Delete</button>
          </div>
        </div>
      ))}
      <button onClick={() => setEditing('new')} className={primaryBtn}>+ Add New Address</button>
    </div>
  );
}

// ─── Vouchers ────────────────────────────────────────────────
function VouchersTab() {
  const [list, setList] = useState<any[] | null>(null);
  const [copied, setCopied] = useState('');
  useEffect(() => {
    fetchApi('/coupons').then((r) => setList(r.data || [])).catch(() => setList([]));
  }, []);

  if (!list) return <Loading />;
  if (list.length === 0) return <Empty icon="🎟️" text="No vouchers are available right now." />;
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
      {list.map((c) => (
        <div key={c.id} className={`${card} border-dashed space-y-2`}>
          <p className="font-mono font-black text-lg text-amber-400 tracking-wider">{c.code}</p>
          <p className="text-xs text-stone-300">{c.description || (c.type === 'PERCENTAGE' ? `${toNumber(c.value)}% off` : `PKR ${toNumber(c.value)} off`)}</p>
          <p className="text-[11px] text-stone-500">
            {toNumber(c.minOrderAmount) > 0 ? `Min order PKR ${toNumber(c.minOrderAmount)}` : 'No minimum order'}
            {c.expiresAt ? ` · Valid until ${new Date(c.expiresAt).toLocaleDateString()}` : ''}
          </p>
          <button
            onClick={() => {
              navigator.clipboard?.writeText(c.code).catch(() => {});
              setCopied(c.code);
            }}
            className={ghostBtn}
          >
            {copied === c.code ? '✓ Copied — paste it at checkout' : 'Copy code'}
          </button>
        </div>
      ))}
    </div>
  );
}

// ─── Loyalty ─────────────────────────────────────────────────
function LoyaltyTab() {
  const [acct, setAcct] = useState<any | null>(null);
  useEffect(() => {
    fetchApi('/loyalty/me').then((r) => setAcct(r.data || { points: 0, lifetime: 0, transactions: [] })).catch(() => setAcct({ points: 0, lifetime: 0, transactions: [] }));
  }, []);
  if (!acct) return <Loading />;
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <div className={card}>
          <p className="text-[11px] uppercase font-bold text-stone-500">Points balance</p>
          <p className="text-3xl font-black text-amber-400">{acct.points}</p>
        </div>
        <div className={card}>
          <p className="text-[11px] uppercase font-bold text-stone-500">Lifetime earned</p>
          <p className="text-3xl font-black text-stone-100">{acct.lifetime}</p>
        </div>
      </div>
      <p className="text-xs text-stone-500">You earn 1 point for every PKR 100 on delivered orders.</p>
      <div className="space-y-2">
        {(acct.transactions || []).length === 0 && <Empty icon="⭐" text="No points activity yet." />}
        {(acct.transactions || []).map((t: any) => (
          <div key={t.id} className={`${card} flex justify-between items-center py-3`}>
            <div>
              <p className="text-xs font-bold text-stone-200">{t.notes || t.type}</p>
              <p className="text-[11px] text-stone-500">{dateText(t.createdAt)}</p>
            </div>
            <span className={`font-black ${t.points >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>{t.points > 0 ? '+' : ''}{t.points}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Notifications ───────────────────────────────────────────
function NotificationsTab() {
  const [list, setList] = useState<any[] | null>(null);
  const load = useCallback(() => {
    fetchApi('/notifications').then((r) => setList(r.data || [])).catch(() => setList([]));
  }, []);
  useEffect(load, [load]);

  if (!list) return <Loading />;
  if (list.length === 0) return <Empty icon="🔔" text="You're all caught up." />;
  return (
    <div className="space-y-2">
      <button
        onClick={async () => {
          await fetchApi('/notifications/read-all', { method: 'PATCH' }).catch(() => {});
          load();
        }}
        className={ghostBtn}
      >
        Mark all as read
      </button>
      {list.map((n) => (
        <div key={n.id} className={`${card} py-3 ${n.isRead ? 'opacity-60' : ''}`}>
          <p className="text-sm font-bold text-stone-100">{n.title}</p>
          <p className="text-xs text-stone-400 mt-0.5">{n.body}</p>
          <p className="text-[11px] text-stone-600 mt-1">{dateText(n.createdAt)}</p>
        </div>
      ))}
    </div>
  );
}

// ─── Branches ────────────────────────────────────────────────
function BranchesTab() {
  const { branches, selectedBranchId, setSelectedBranchId, setOrderType } = useBranch();
  const [q, setQ] = useState('');
  const shown = branches.filter((b) => `${b.name} ${b.address}`.toLowerCase().includes(q.toLowerCase()));

  return (
    <div className="space-y-3">
      <input className={input} value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search by branch" />
      {shown.length === 0 && <Empty icon="🏬" text="No branches found." />}
      {shown.map((b) => (
        <div key={b.id} className={`${card} flex items-center justify-between gap-3`}>
          <div>
            <p className="font-black text-sm">{b.name}</p>
            <p className="text-xs text-stone-400">{b.address}{b.city ? `, ${b.city}` : ''}</p>
            <p className={`text-[11px] font-bold mt-0.5 ${b.isOpen ? 'text-emerald-400' : 'text-red-400'}`}>{b.isOpen ? 'Open Now' : 'Closed'}</p>
          </div>
          <div className="flex flex-col gap-2 shrink-0">
            <Link
              to="/"
              onClick={() => {
                setSelectedBranchId(b.id);
                setOrderType('PICKUP');
              }}
              className={primaryBtn}
            >
              {selectedBranchId === b.id ? 'Selected · Order' : 'Pickup here'}
            </Link>
          </div>
        </div>
      ))}
    </div>
  );
}

// ─── Profile ─────────────────────────────────────────────────
function ProfileTab() {
  const { user, logout } = useAuth();
  const [name, setName] = useState(user?.name ?? '');
  const [email, setEmail] = useState(user?.email ?? '');
  const [phone, setPhone] = useState(user?.phone ?? '');
  const [msg, setMsg] = useState('');
  const [oldPassword, setOld] = useState('');
  const [newPassword, setNew] = useState('');
  const [pwMsg, setPwMsg] = useState('');

  useEffect(() => {
    fetchApi('/customers/profile')
      .then((r) => {
        if (r.success) {
          setName(r.data.name ?? '');
          setEmail(r.data.email ?? '');
          setPhone(r.data.phone ?? '');
        }
      })
      .catch(() => {});
  }, []);

  const saveProfile = async () => {
    setMsg('');
    try {
      const res = await fetchApi('/customers/profile', { method: 'PUT', body: JSON.stringify({ name: name.trim(), email: email.trim(), phone: phone.trim() }) });
      if (res.success) {
        try {
          const saved = JSON.parse(localStorage.getItem('hp_user') || '{}');
          localStorage.setItem('hp_user', JSON.stringify({ ...saved, name: res.data.name, email: res.data.email, phone: res.data.phone }));
        } catch {
          /* header name refreshes on next sign-in */
        }
        setMsg('✓ Profile updated');
      } else setMsg(res.message || 'Could not update your profile.');
    } catch (e: any) {
      setMsg(e.message || 'Could not update your profile.');
    }
  };

  const changePassword = async () => {
    setPwMsg('');
    if (newPassword.length < 8) return setPwMsg('New password must be at least 8 characters.');
    try {
      const res = await fetchApi('/auth/change-password', { method: 'PUT', body: JSON.stringify({ oldPassword, newPassword }) });
      setPwMsg(res.success ? '✓ Password changed' : res.message || 'Could not change the password.');
      if (res.success) {
        setOld('');
        setNew('');
      }
    } catch (e: any) {
      setPwMsg(e.message || 'Could not change the password.');
    }
  };

  const deactivate = async () => {
    if (!window.confirm('Delete your account? This cannot be undone.')) return;
    try {
      await fetchApi('/customers/account', { method: 'DELETE' });
      logout();
    } catch (e: any) {
      window.alert(e.message || 'Could not delete the account.');
    }
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div className={`${card} space-y-3`}>
        <h3 className="font-black text-sm">Personal details</h3>
        <input className={input} value={name} onChange={(e) => setName(e.target.value)} placeholder="Full name" />
        <input className={input} value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" type="email" />
        <input className={input} value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="Mobile number" type="tel" />
        {msg && <p className={`text-xs font-semibold ${msg.startsWith('✓') ? 'text-emerald-400' : 'text-red-400'}`}>{msg}</p>}
        <button onClick={saveProfile} className={primaryBtn}>Save changes</button>
      </div>
      <div className={`${card} space-y-3`}>
        <h3 className="font-black text-sm">Change password</h3>
        <input className={input} type="password" value={oldPassword} onChange={(e) => setOld(e.target.value)} placeholder="Current password" autoComplete="current-password" />
        <input className={input} type="password" value={newPassword} onChange={(e) => setNew(e.target.value)} placeholder="New password (8+ characters)" autoComplete="new-password" />
        {pwMsg && <p className={`text-xs font-semibold ${pwMsg.startsWith('✓') ? 'text-emerald-400' : 'text-red-400'}`}>{pwMsg}</p>}
        <button onClick={changePassword} className={primaryBtn}>Update password</button>
        <div className="border-t border-stone-800 pt-3 flex gap-2">
          <button onClick={logout} className={ghostBtn}>Log out</button>
          <button onClick={deactivate} className={`${ghostBtn} text-red-400`}>Delete account</button>
        </div>
      </div>
    </div>
  );
}

// ─── Small helpers ───────────────────────────────────────────
function Loading() {
  return (
    <div className="flex justify-center py-16">
      <div className="w-8 h-8 border-4 border-amber-500 border-t-transparent rounded-full animate-spin" />
    </div>
  );
}
function Empty({ icon, text }: { icon: string; text: string }) {
  return (
    <div className="text-center py-14 bg-stone-900/50 rounded-2xl border border-stone-800/80">
      <span className="text-4xl block mb-2">{icon}</span>
      <p className="text-sm text-stone-400 font-semibold">{text}</p>
    </div>
  );
}
