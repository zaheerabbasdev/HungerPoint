// ============================================================
// HungerPoint Web App — Customer Live Order Tracking Page
// ============================================================

'use client';

import React, { useState, useEffect, use } from 'react';
import { fetchApi } from '../../../lib/api';
import Link from 'next/link';

const STATUS_STEPS = [
  { key: 'PENDING', label: 'Order Received', icon: '📝' },
  { key: 'CONFIRMED', label: 'Confirmed', icon: '✓' },
  { key: 'PREPARING', label: 'In Kitchen', icon: '🍳' },
  { key: 'READY', label: 'Ready for Pickup', icon: '📦' },
  { key: 'OUT_FOR_DELIVERY', label: 'Out for Delivery', icon: '🛵' },
  { key: 'DELIVERED', label: 'Delivered', icon: '🎉' },
];

export default function OrderTrackingPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [order, setOrder] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadOrder() {
      try {
        const res = await fetchApi(`/orders/${id}`);
        if (res.success) setOrder(res.data);
      } catch (err) {
        console.error('Failed to load order tracking:', err);
      } finally {
        setLoading(false);
      }
    }
    loadOrder();

    // Auto-poll for live status updates
    const interval = setInterval(loadOrder, 5000);
    return () => clearInterval(interval);
  }, [id]);

  if (loading) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center p-4">
        <div className="text-center space-y-3">
          <div className="w-12 h-12 border-4 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-xs text-stone-400 font-bold">Loading your order status...</p>
        </div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center p-4">
        <div className="text-center space-y-4 max-w-sm">
          <span className="text-4xl block">🔍</span>
          <h2 className="text-xl font-bold">Order Not Found</h2>
          <p className="text-xs text-stone-400">We couldn't find the requested order tracking details.</p>
          <Link
            href="/"
            className="inline-block px-5 py-2.5 bg-amber-500 text-stone-950 font-bold text-xs rounded-xl"
          >
            Back to Home
          </Link>
        </div>
      </div>
    );
  }

  const currentStepIndex = STATUS_STEPS.findIndex((s) => s.key === order.status);

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 p-4 sm:p-8">
      <div className="max-w-3xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="flex justify-between items-center pb-4 border-b border-stone-800">
          <div>
            <Link href="/" className="text-xs text-amber-400 font-bold hover:underline">
              ← Back to Storefront
            </Link>
            <h1 className="text-2xl font-black text-stone-100 mt-1">Live Order Tracker</h1>
          </div>
          <div className="text-right">
            <span className="text-[10px] text-stone-400 uppercase tracking-widest block font-bold">Order Number</span>
            <span className="font-mono font-black text-amber-400 text-base">{order.orderNumber}</span>
          </div>
        </div>

        {/* Live Stepper */}
        <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 sm:p-8 space-y-6 shadow-2xl">
          <div className="flex justify-between items-center">
            <h3 className="text-sm font-extrabold uppercase tracking-wider text-stone-400">Delivery Status</h3>
            <span className="px-3 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-black rounded-full uppercase">
              {order.status}
            </span>
          </div>

          {/* Stepper Bar */}
          <div className="grid grid-cols-6 gap-2 pt-4 relative">
            {STATUS_STEPS.map((step, idx) => {
              const isCompleted = idx <= currentStepIndex;
              const isCurrent = idx === currentStepIndex;

              return (
                <div key={step.key} className="flex flex-col items-center text-center space-y-2">
                  <div
                    className={`w-10 h-10 rounded-2xl flex items-center justify-center text-sm font-bold transition-all ${
                      isCurrent
                        ? 'bg-gradient-to-r from-amber-500 to-orange-600 text-white shadow-lg shadow-orange-500/40 ring-4 ring-orange-500/20'
                        : isCompleted
                        ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40'
                        : 'bg-stone-800 text-stone-600 border border-stone-700/50'
                    }`}
                  >
                    {step.icon}
                  </div>
                  <span
                    className={`text-[10px] font-bold leading-tight ${
                      isCurrent
                        ? 'text-amber-400 font-extrabold'
                        : isCompleted
                        ? 'text-stone-300'
                        : 'text-stone-600'
                    }`}
                  >
                    {step.label}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Order Details & Summary */}
        <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 space-y-4">
          <h3 className="text-base font-extrabold text-stone-100">Order Items</h3>
          
          <div className="divide-y divide-stone-800">
            {order.items?.map((item: any) => (
              <div key={item.id} className="py-3 flex justify-between items-center text-xs">
                <div>
                  <span className="font-bold text-stone-200">{item.quantity}x {item.product?.name}</span>
                  {item.variant?.name && (
                    <span className="text-[10px] text-amber-400 block font-medium">Size: {item.variant.name}</span>
                  )}
                </div>
                <span className="font-mono font-bold text-stone-300">
                  PKR {Number(item.totalPrice).toFixed(2)}
                </span>
              </div>
            ))}
          </div>

          <div className="border-t border-stone-800 pt-4 space-y-1.5 text-xs text-stone-400">
            <div className="flex justify-between">
              <span>Subtotal</span>
              <span>PKR {Number(order.subtotal).toFixed(2)}</span>
            </div>
            <div className="flex justify-between">
              <span>Delivery Fee</span>
              <span>PKR {Number(order.deliveryFee).toFixed(2)}</span>
            </div>
            <div className="flex justify-between">
              <span>Tax (5%)</span>
              <span>PKR {Number(order.tax).toFixed(2)}</span>
            </div>
            <div className="flex justify-between text-sm font-black text-stone-100 pt-2 border-t border-stone-800">
              <span>Total Paid ({order.paymentMethod})</span>
              <span className="text-amber-400">PKR {Number(order.total).toFixed(2)}</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
