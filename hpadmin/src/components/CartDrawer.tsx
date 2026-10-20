// ============================================================
// HungerPoint Web App — Cart Drawer & Checkout
// ============================================================
// Same checkout as the mobile app: delivery (saved address, checked against the
// branch's delivery radius) or pickup (choose a branch), a voucher, a payment
// method and notes. The server prices the order; the bill here is an estimate.

import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import { useBranch } from '../context/BranchContext';
import { fetchApi, resolveImageUrl } from '../lib/api';
import { buildOrderItems, estimateTotals } from '../lib/menu';
import { AddressForm, type SavedAddress } from './AddressForm';

const PAYMENT_METHODS = [
  { value: 'CASH_ON_DELIVERY', label: '💵 Cash', pickupLabel: '💵 Cash at pickup' },
  { value: 'JAZZCASH', label: '📱 JazzCash', pickupLabel: '📱 JazzCash' },
  { value: 'EASYPAISA', label: '📱 Easypaisa', pickupLabel: '📱 Easypaisa' },
  { value: 'CREDIT_CARD', label: '💳 Debit / Credit Card', pickupLabel: '💳 Debit / Credit Card' },
] as const;

const addressTitle = (a: SavedAddress) => (a.label === 'OTHER' ? a.customName || 'Other' : a.label === 'HOME' ? 'Home' : 'Work');

export function CartDrawer({ onRequireAuth }: { onRequireAuth: () => void }) {
  const { items, isCartOpen, setIsCartOpen, updateQuantity, removeItem, clearCart } = useCart();
  const { user } = useAuth();
  const { branches, selectedBranchId, setSelectedBranchId, orderType, setOrderType } = useBranch();

  const [addresses, setAddresses] = useState<SavedAddress[]>([]);
  const [addressId, setAddressId] = useState<string | null>(null);
  const [showAddressForm, setShowAddressForm] = useState(false);
  const [rangeProblem, setRangeProblem] = useState('');

  const [paymentMethod, setPaymentMethod] = useState<(typeof PAYMENT_METHODS)[number]['value']>('CASH_ON_DELIVERY');
  const [notes, setNotes] = useState('');

  const [couponInput, setCouponInput] = useState('');
  const [coupon, setCoupon] = useState<{ code: string; discount: number } | null>(null);
  const [couponMessage, setCouponMessage] = useState('');
  const [applying, setApplying] = useState(false);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [orderSuccess, setOrderSuccess] = useState<any | null>(null);

  const isCustomer = user?.role === 'CUSTOMER';
  const totals = estimateTotals(items, orderType, coupon?.discount ?? 0);

  const loadAddresses = useCallback(async () => {
    if (!isCustomer) return setAddresses([]);
    try {
      const res = await fetchApi('/customers/addresses');
      if (res.success) {
        const list: SavedAddress[] = res.data || [];
        setAddresses(list);
        setAddressId((cur) => (cur && list.some((a) => a.id === cur) ? cur : list.find((a) => a.isDefault)?.id ?? list[0]?.id ?? null));
      }
    } catch {
      /* the checkout will say what is missing */
    }
  }, [isCustomer]);

  useEffect(() => {
    if (isCartOpen) loadAddresses();
  }, [isCartOpen, loadAddresses]);

  // The voucher was checked against an older subtotal: ask again whenever the cart changes.
  useEffect(() => {
    setCoupon(null);
    setCouponMessage('');
  }, [totals.subtotal]);

  // Delivery: pick the nearest open branch whose delivery radius covers the address (same rule as the app).
  const address = addresses.find((a) => a.id === addressId) || null;
  useEffect(() => {
    if (orderType !== 'DELIVERY' || !address || address.latitude == null || address.longitude == null) {
      setRangeProblem('');
      return;
    }
    let alive = true;
    fetchApi(`/branches/nearest?latitude=${address.latitude}&longitude=${address.longitude}`)
      .then((res) => {
        if (!alive || !res.success) return;
        const best = (res.data as any[]).find((b) => b.delivers && b.isOpen);
        if (best) {
          setRangeProblem('');
          setSelectedBranchId(best.id);
        } else {
          setRangeProblem('No open branch delivers to this address. Choose another address or switch to Pickup.');
        }
      })
      .catch(() => {});
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [addressId, orderType, addresses]);

  if (!isCartOpen) return null;

  const close = () => {
    setIsCartOpen(false);
    setOrderSuccess(null);
    setError('');
  };

  const applyCoupon = async () => {
    if (!couponInput.trim()) return;
    setApplying(true);
    setCouponMessage('');
    try {
      const res = await fetchApi('/coupons/validate', { method: 'POST', body: JSON.stringify({ code: couponInput.trim(), amount: totals.subtotal }) });
      if (res.valid) {
        setCoupon({ code: res.code, discount: Number(res.discount) || 0 });
        setCouponMessage(`${res.message} You save PKR ${Number(res.discount) || 0}.`);
      } else {
        setCoupon(null);
        setCouponMessage(res.message || 'Invalid voucher code');
      }
    } catch (e: any) {
      setCoupon(null);
      setCouponMessage(e.message || 'Could not check the voucher.');
    } finally {
      setApplying(false);
    }
  };

  const handleCheckout = async () => {
    setError('');
    if (items.length === 0) return;
    if (!user) return onRequireAuth();
    if (!isCustomer) return setError('Please sign in with a customer account to order. Staff accounts use the POS.');
    if (!selectedBranchId) return setError('Please select a branch.');
    if (orderType === 'DELIVERY') {
      if (!address) return setError('Please add a delivery address.');
      if (rangeProblem) return setError(rangeProblem);
    }

    setIsSubmitting(true);
    try {
      const res = await fetchApi('/orders', {
        method: 'POST',
        body: JSON.stringify({
          branchId: selectedBranchId,
          type: orderType,
          source: 'WEBSITE',
          paymentMethod,
          ...(orderType === 'DELIVERY' && address ? { addressId: address.id } : {}),
          ...(coupon ? { couponCode: coupon.code } : {}),
          ...(notes.trim() ? { notes: notes.trim() } : {}),
          items: buildOrderItems(items),
        }),
      });
      if (res.success) {
        setOrderSuccess(res.data);
        clearCart();
        setCoupon(null);
        setCouponInput('');
        setNotes('');
      } else {
        setError(res.message || 'Failed to place order.');
      }
    } catch (e: any) {
      setError(e.message || 'Failed to place order.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const branch = branches.find((b) => b.id === selectedBranchId) || null;
  const label = 'text-[11px] font-bold text-stone-400 uppercase tracking-wider block mb-1.5';

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/70 backdrop-blur-sm">
      <div className="w-full max-w-md bg-stone-900 text-stone-100 h-full flex flex-col shadow-2xl border-l border-stone-800">
        <div className="p-5 border-b border-stone-800 flex items-center justify-between bg-stone-900/90">
          <div className="flex items-center gap-2">
            <span className="text-xl">🛍️</span>
            <h2 className="text-lg font-bold text-stone-100">Your Food Cart</h2>
          </div>
          <button onClick={close} className="text-stone-400 hover:text-stone-100 text-sm p-2 hover:bg-stone-800 rounded-lg transition-colors" aria-label="Close cart">
            ✕
          </button>
        </div>

        {orderSuccess ? (
          <div className="p-6 flex-1 flex flex-col items-center justify-center text-center space-y-4 overflow-y-auto">
            <div className="w-16 h-16 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center text-3xl">✓</div>
            <h3 className="text-2xl font-black text-emerald-400">Order Placed!</h3>
            <p className="text-sm text-stone-300">
              Order <span className="font-mono font-bold text-amber-400">{orderSuccess.orderNumber}</span> has been sent to {orderSuccess.branch?.name || 'the branch'}.
            </p>
            <div className="w-full bg-stone-800/80 p-4 rounded-xl text-xs space-y-2 text-stone-300 text-left border border-stone-700/50">
              <div className="flex justify-between">
                <span>Total Amount</span>
                <span className="font-bold text-amber-400">PKR {Number(orderSuccess.total).toFixed(2)}</span>
              </div>
              <div className="flex justify-between">
                <span>Status</span>
                <span className="font-semibold text-emerald-400 uppercase">{orderSuccess.status}</span>
              </div>
            </div>
            <Link
              to={`/orders/${orderSuccess.id}`}
              onClick={close}
              className="block text-center w-full py-3 bg-gradient-to-r from-amber-500 to-orange-600 font-bold text-white rounded-xl shadow-lg"
            >
              Track My Order
            </Link>
            <button onClick={close} className="w-full py-3 border border-stone-700 font-bold text-stone-300 rounded-xl hover:bg-stone-800">
              Continue Shopping
            </button>
          </div>
        ) : (
          <>
            <div className="flex-1 overflow-y-auto p-5 space-y-5">
              {items.length === 0 ? (
                <div className="text-center py-16 space-y-3 text-stone-500">
                  <span className="text-4xl block">🛒</span>
                  <p className="text-sm font-semibold">Your cart is empty</p>
                  <p className="text-xs">Add delicious items from the menu to get started!</p>
                </div>
              ) : (
                <>
                  <div className="space-y-3">
                    {items.map((item) => (
                      <div key={item.id} className="p-3 bg-stone-800/60 rounded-xl border border-stone-800 flex gap-3">
                        {item.image && <img src={resolveImageUrl(item.image)} alt={item.name} className="w-14 h-14 object-cover rounded-lg shrink-0" />}
                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between gap-2">
                            <h4 className="text-xs font-bold text-stone-200 truncate">{item.name}</h4>
                            <button onClick={() => removeItem(item.id)} title="Remove" className="text-stone-500 hover:text-red-400 text-xs shrink-0">
                              🗑
                            </button>
                          </div>
                          {item.variantName && <p className="text-[10px] text-amber-400 font-medium">{item.variantName}</p>}
                          {item.flavour && <p className="text-[10px] text-stone-400">Flavour: {item.flavour}</p>}
                          {item.addons.length > 0 && <p className="text-[10px] text-stone-400">+ {item.addons.map((a) => a.name).join(', ')}</p>}
                          {item.drinkName && <p className="text-[10px] text-stone-400">🥤 {item.drinkName}</p>}
                          {item.notes && <p className="text-[10px] text-stone-500 italic">“{item.notes}”</p>}
                          <div className="flex items-center justify-between mt-1.5">
                            <p className="text-xs font-extrabold text-stone-100">PKR {(item.unitPrice * item.quantity).toFixed(0)}</p>
                            <div className="flex items-center gap-2 bg-stone-900 px-2 py-0.5 rounded-lg border border-stone-700/60">
                              <button onClick={() => updateQuantity(item.id, item.quantity - 1)} className="text-stone-400 hover:text-stone-100 text-xs font-bold px-1">
                                -
                              </button>
                              <span className="text-xs font-bold text-amber-400 w-4 text-center">{item.quantity}</span>
                              <button onClick={() => updateQuantity(item.id, item.quantity + 1)} className="text-stone-400 hover:text-stone-100 text-xs font-bold px-1">
                                +
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Delivery / Pickup */}
                  <div>
                    <span className={label}>Order Type</span>
                    <div className="grid grid-cols-2 gap-2">
                      {(['DELIVERY', 'PICKUP'] as const).map((t) => (
                        <button
                          key={t}
                          type="button"
                          onClick={() => setOrderType(t)}
                          className={`p-2 rounded-xl text-xs font-bold border text-center transition-all ${
                            orderType === t ? 'border-amber-500 bg-amber-500/10 text-amber-400' : 'border-stone-800 text-stone-400'
                          }`}
                        >
                          {t === 'DELIVERY' ? '🛵 Delivery' : '🛍️ Pickup'}
                        </button>
                      ))}
                    </div>
                  </div>

                  {orderType === 'PICKUP' ? (
                    <div>
                      <span className={label}>Pickup From</span>
                      <select
                        value={selectedBranchId ?? ''}
                        onChange={(e) => setSelectedBranchId(e.target.value)}
                        className="w-full bg-stone-900 border border-stone-800 rounded-xl px-3 py-2 text-xs text-stone-200 outline-none focus:border-amber-500"
                      >
                        {branches.map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.name} {b.isOpen ? '' : '(closed)'}
                          </option>
                        ))}
                      </select>
                      {branch && <p className="text-[11px] text-stone-500 mt-1">{branch.address}</p>}
                    </div>
                  ) : (
                    <div>
                      <span className={label}>Deliver To</span>
                      {!isCustomer ? (
                        <button type="button" onClick={onRequireAuth} className="text-xs font-extrabold text-amber-400 hover:underline">
                          Sign in to choose a delivery address (your cart is saved)
                        </button>
                      ) : showAddressForm ? (
                        <div className="bg-stone-950 border border-stone-800 rounded-xl p-3">
                          <AddressForm
                            onCancel={() => setShowAddressForm(false)}
                            onSaved={(a) => {
                              setShowAddressForm(false);
                              setAddresses((prev) => [a, ...prev.filter((x) => x.id !== a.id)]);
                              setAddressId(a.id);
                            }}
                          />
                        </div>
                      ) : (
                        <div className="space-y-2">
                          {addresses.map((a) => (
                            <button
                              key={a.id}
                              type="button"
                              onClick={() => setAddressId(a.id)}
                              className={`w-full text-left p-3 rounded-xl border text-xs transition-all ${
                                addressId === a.id ? 'border-amber-500 bg-amber-500/10' : 'border-stone-800 bg-stone-900 hover:border-stone-700'
                              }`}
                            >
                              <span className="font-bold text-stone-100">{addressTitle(a)}</span>
                              <span className="block text-stone-400 mt-0.5 line-clamp-2">{a.address}</span>
                            </button>
                          ))}
                          <button type="button" onClick={() => setShowAddressForm(true)} className="text-xs font-extrabold text-amber-400 hover:underline">
                            + Add new address
                          </button>
                          {rangeProblem && <p className="text-xs font-semibold text-red-400">{rangeProblem}</p>}
                          {!rangeProblem && branch && address && <p className="text-[11px] text-stone-500">Prepared at {branch.name}</p>}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Voucher */}
                  <div>
                    <span className={label}>Voucher</span>
                    <div className="flex gap-2">
                      <input
                        value={couponInput}
                        onChange={(e) => setCouponInput(e.target.value.toUpperCase())}
                        placeholder="Enter code"
                        className="flex-1 bg-stone-900 border border-stone-800 rounded-xl px-3 py-2 text-xs text-stone-200 outline-none focus:border-amber-500 font-mono"
                      />
                      <button onClick={applyCoupon} disabled={applying || !couponInput.trim()} className="px-4 py-2 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl disabled:opacity-40">
                        {applying ? '…' : 'Apply'}
                      </button>
                    </div>
                    {couponMessage && <p className={`text-[11px] mt-1 font-semibold ${coupon ? 'text-emerald-400' : 'text-red-400'}`}>{couponMessage}</p>}
                  </div>

                  {/* Payment */}
                  <div>
                    <span className={label}>Payment Method</span>
                    <div className="grid grid-cols-2 gap-2">
                      {PAYMENT_METHODS.map((m) => (
                        <button
                          key={m.value}
                          type="button"
                          onClick={() => setPaymentMethod(m.value)}
                          className={`p-2 rounded-xl text-[11px] font-bold border text-center transition-all ${
                            paymentMethod === m.value ? 'border-amber-500 bg-amber-500/10 text-amber-400' : 'border-stone-800 text-stone-400'
                          }`}
                        >
                          {orderType === 'PICKUP' ? m.pickupLabel : m.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div>
                    <span className={label}>Order Notes</span>
                    <input
                      value={notes}
                      onChange={(e) => setNotes(e.target.value)}
                      placeholder="Anything the branch should know (optional)"
                      className="w-full bg-stone-900 border border-stone-800 rounded-xl px-3 py-2 text-xs text-stone-200 outline-none focus:border-amber-500"
                    />
                  </div>
                </>
              )}
            </div>

            {items.length > 0 && (
              <div className="p-5 border-t border-stone-800 bg-stone-950/80 space-y-3">
                <div className="space-y-1 text-xs text-stone-400">
                  <div className="flex justify-between"><span>Subtotal</span><span>PKR {totals.subtotal.toFixed(2)}</span></div>
                  {totals.discount > 0 && <div className="flex justify-between text-emerald-400"><span>Voucher ({coupon?.code})</span><span>− PKR {totals.discount.toFixed(2)}</span></div>}
                  <div className="flex justify-between"><span>Delivery Fee</span><span>PKR {totals.deliveryFee.toFixed(2)}</span></div>
                  <div className="flex justify-between"><span>Tax (5%)</span><span>PKR {totals.tax.toFixed(2)}</span></div>
                  <div className="flex justify-between text-sm font-extrabold text-stone-100 pt-2 border-t border-stone-800">
                    <span>Total (estimate)</span>
                    <span className="text-amber-400">PKR {totals.total.toFixed(2)}</span>
                  </div>
                </div>
                {error && <p className="text-xs font-semibold text-red-400">{error}</p>}
                {!user && <p className="text-[11px] text-stone-500 text-center">Sign in or create an account to place your order — your cart stays as it is.</p>}
                <button
                  onClick={handleCheckout}
                  disabled={isSubmitting}
                  className="w-full py-3.5 bg-gradient-to-r from-amber-500 via-orange-600 to-red-600 hover:from-amber-600 hover:to-red-700 text-white font-extrabold text-sm rounded-xl shadow-lg shadow-orange-500/30 transition-all active:scale-95 disabled:opacity-50"
                >
                  {isSubmitting ? 'Placing Order…' : user ? `Place Order (PKR ${totals.total.toFixed(0)})` : 'Sign in to Order'}
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
