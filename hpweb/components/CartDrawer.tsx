// ============================================================
// HungerPoint Web App — Cart Drawer & Checkout Modal
// ============================================================

'use client';

import React, { useState } from 'react';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import { useBranch } from '../context/BranchContext';
import { fetchApi } from '../lib/api';

export function CartDrawer() {
  const { items, isCartOpen, setIsCartOpen, updateQuantity, removeItem, clearCart, subtotal, deliveryFee, tax, total } = useCart();
  const { user } = useAuth();
  const { selectedBranchId } = useBranch();

  const [paymentMethod, setPaymentMethod] = useState<'CASH_ON_DELIVERY' | 'ONLINE_CARD'>('CASH_ON_DELIVERY');
  const [address, setAddress] = useState('Flat 402, Al-Rehman Heights, G-11/3, Islamabad');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState<any | null>(null);

  if (!isCartOpen) return null;

  const handleCheckout = async () => {
    if (!user) {
      alert('Please sign in to place an order.');
      return;
    }

    if (items.length === 0) return;

    if (!selectedBranchId) {
      alert('Please select a branch before checking out.');
      return;
    }

    setIsSubmitting(true);
    try {
      const orderPayload = {
        branchId: selectedBranchId,
        paymentMethod,
        source: 'WEBSITE',
        notes,
        items: items.map((i) => ({
          productId: i.productId,
          variantId: i.variantId,
          quantity: i.quantity,
          notes: i.notes,
        })),
      };

      const res = await fetchApi('/orders', {
        method: 'POST',
        body: JSON.stringify(orderPayload),
      });

      if (res.success) {
        setOrderSuccess(res.data);
        await clearCart();
      }
    } catch (error: any) {
      alert(error.message || 'Failed to place order.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/70 backdrop-blur-sm transition-opacity">
      <div className="w-full max-w-md bg-stone-900 text-stone-100 h-full flex flex-col shadow-2xl border-l border-stone-800">
        
        {/* Drawer Header */}
        <div className="p-5 border-b border-stone-800 flex items-center justify-between bg-stone-900/90">
          <div className="flex items-center gap-2">
            <span className="text-xl">🛍️</span>
            <h2 className="text-lg font-bold text-stone-100">Your Food Cart</h2>
          </div>
          <button
            onClick={() => {
              setIsCartOpen(false);
              setOrderSuccess(null);
            }}
            className="text-stone-400 hover:text-stone-100 text-sm p-2 hover:bg-stone-800 rounded-lg transition-colors"
          >
            ✕
          </button>
        </div>

        {orderSuccess ? (
          /* Order Confirmation Screen */
          <div className="p-6 flex-1 flex flex-col items-center justify-center text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center text-3xl">
              ✓
            </div>
            <h3 className="text-2xl font-black text-emerald-400">Order Confirmed!</h3>
            <p className="text-sm text-stone-300">
              Order <span className="font-mono font-bold text-amber-400">{orderSuccess.orderNumber}</span> has been placed successfully.
            </p>
            <div className="w-full bg-stone-800/80 p-4 rounded-xl text-xs space-y-2 text-stone-300 text-left border border-stone-700/50">
              <div className="flex justify-between">
                <span>Total Amount:</span>
                <span className="font-bold text-amber-400">PKR {Number(orderSuccess.total).toFixed(2)}</span>
              </div>
              <div className="flex justify-between">
                <span>Status:</span>
                <span className="font-semibold text-emerald-400 uppercase">{orderSuccess.status}</span>
              </div>
            </div>
            <button
              onClick={() => {
                setIsCartOpen(false);
                setOrderSuccess(null);
              }}
              className="w-full py-3 bg-gradient-to-r from-amber-500 to-orange-600 font-bold text-white rounded-xl shadow-lg"
            >
              Continue Shopping
            </button>
          </div>
        ) : (
          <>
            {/* Cart Items List */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              {items.length === 0 ? (
                <div className="text-center py-16 space-y-3 text-stone-500">
                  <span className="text-4xl block">🛒</span>
                  <p className="text-sm font-semibold">Your cart is empty</p>
                  <p className="text-xs">Add delicious items from the menu to get started!</p>
                </div>
              ) : (
                items.map((item) => (
                  <div
                    key={item.id}
                    className="p-3 bg-stone-800/60 rounded-xl border border-stone-800 flex items-center justify-between gap-3"
                  >
                    {item.image && (
                      <img src={item.image} alt={item.name} className="w-14 h-14 object-cover rounded-lg" />
                    )}
                    <div className="flex-1 min-w-0">
                      <h4 className="text-xs font-bold text-stone-200 truncate">{item.name}</h4>
                      {item.variantName && (
                        <p className="text-[10px] text-amber-400 font-medium">{item.variantName}</p>
                      )}
                      <p className="text-xs font-extrabold text-stone-100 mt-1">
                        PKR {(item.price * item.quantity).toFixed(2)}
                      </p>
                    </div>

                    {/* Quantity Controls */}
                    <div className="flex items-center gap-2 bg-stone-900 px-2 py-1 rounded-lg border border-stone-700/60">
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                        className="text-stone-400 hover:text-stone-100 text-xs font-bold px-1"
                      >
                        -
                      </button>
                      <span className="text-xs font-bold text-amber-400 w-4 text-center">{item.quantity}</span>
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                        className="text-stone-400 hover:text-stone-100 text-xs font-bold px-1"
                      >
                        +
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Checkout & Bill Summary */}
            {items.length > 0 && (
              <div className="p-5 border-t border-stone-800 bg-stone-950/80 space-y-4">
                {/* Delivery Address Input */}
                <div>
                  <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider block mb-1">
                    Delivery Address
                  </label>
                  <input
                    type="text"
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    className="w-full bg-stone-900 border border-stone-800 rounded-xl px-3 py-2 text-xs text-stone-200 focus:border-amber-500 outline-none"
                  />
                </div>

                {/* Payment Method Selector */}
                <div>
                  <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider block mb-1">
                    Payment Method
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setPaymentMethod('CASH_ON_DELIVERY')}
                      className={`p-2 rounded-xl text-xs font-bold border text-center transition-all ${
                        paymentMethod === 'CASH_ON_DELIVERY'
                          ? 'border-amber-500 bg-amber-500/10 text-amber-400'
                          : 'border-stone-800 text-stone-400'
                      }`}
                    >
                      💵 Cash on Delivery
                    </button>
                    <button
                      type="button"
                      onClick={() => setPaymentMethod('ONLINE_CARD')}
                      className={`p-2 rounded-xl text-xs font-bold border text-center transition-all ${
                        paymentMethod === 'ONLINE_CARD'
                          ? 'border-amber-500 bg-amber-500/10 text-amber-400'
                          : 'border-stone-800 text-stone-400'
                      }`}
                    >
                      💳 Credit/Debit Card
                    </button>
                  </div>
                </div>

                {/* Price Breakdown */}
                <div className="space-y-1 text-xs text-stone-400 border-t border-stone-800 pt-3">
                  <div className="flex justify-between">
                    <span>Subtotal</span>
                    <span>PKR {subtotal.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Delivery Fee</span>
                    <span>PKR {deliveryFee.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Tax (5%)</span>
                    <span>PKR {tax.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-sm font-extrabold text-stone-100 pt-2 border-t border-stone-800">
                    <span>Total Amount</span>
                    <span className="text-amber-400">PKR {total.toFixed(2)}</span>
                  </div>
                </div>

                {/* Place Order Button */}
                <button
                  onClick={handleCheckout}
                  disabled={isSubmitting}
                  className="w-full py-3.5 bg-gradient-to-r from-amber-500 via-orange-600 to-red-600 hover:from-amber-600 hover:to-red-700 text-white font-extrabold text-sm rounded-xl shadow-lg shadow-orange-500/30 transition-all transform active:scale-95 disabled:opacity-50"
                >
                  {isSubmitting ? 'Placing Order...' : `Place Order (PKR ${total.toFixed(2)})`}
                </button>
              </div>
            )}
          </>
        )}

      </div>
    </div>
  );
}
