// ============================================================
// HungerPoint Web App — Review Moderation
// Route: /reviews
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';

const REVIEWS_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN', 'BRANCH_MANAGER'];

function Stars({ rating }: { rating: number }) {
  return (
    <span className="text-amber-400 tracking-wide">
      {'★'.repeat(rating)}
      <span className="text-stone-700">{'★'.repeat(5 - rating)}</span>
    </span>
  );
}

export default function ReviewsPage() {
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [reviews, setReviews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'ALL' | 'APPROVED' | 'HIDDEN'>('ALL');
  const [toast, setToast] = useState<string | null>(null);

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
    if (!token || !user || !REVIEWS_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadReviews = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchApi('/reviews');
      if (res.success) setReviews(res.data);
    } catch (err) {
      console.error('Failed to load reviews:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authorized) loadReviews();
  }, [authorized, loadReviews]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const toggleApproval = async (review: any) => {
    try {
      const res = await fetchApi(`/reviews/${review.id}/approval`, {
        method: 'PATCH',
        body: JSON.stringify({ isApproved: !review.isApproved }),
      });
      if (res.success) {
        showToast(review.isApproved ? 'Review hidden' : 'Review approved');
        await loadReviews();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update review');
    }
  };

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Checking access...</p>
      </div>
    );
  }
  if (!authorized) return null;

  const filtered = reviews.filter((r) => {
    if (filter === 'APPROVED') return r.isApproved;
    if (filter === 'HIDDEN') return !r.isApproved;
    return true;
  });

  const avgRating = reviews.length ? (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1) : '—';

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100">
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-stone-900 border border-amber-500/40 text-amber-400 text-xs font-bold px-4 py-2.5 rounded-xl shadow-xl">
          {toast}
        </div>
      )}

      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 flex-wrap">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>💬</span> Review Moderation</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-sm font-black text-amber-400">{avgRating} <span className="text-stone-500 text-xs font-normal">avg / {reviews.length} reviews</span></p>
            </div>
            <select value={filter} onChange={(e) => setFilter(e.target.value as any)}
              className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-1.5 text-xs text-stone-200 outline-none">
              <option value="ALL">All</option>
              <option value="APPROVED">Visible</option>
              <option value="HIDDEN">Hidden</option>
            </select>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6 space-y-3">
        {loading ? (
          <div className="text-center py-16 text-stone-500 text-sm">Loading reviews...</div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 text-stone-500 text-sm">No reviews found.</div>
        ) : (
          filtered.map((r) => (
            <div key={r.id} className="bg-stone-900 border border-stone-800 rounded-2xl p-4 flex items-start justify-between gap-4">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <Stars rating={r.rating} />
                  <span className="text-xs font-bold text-stone-200">{r.customer?.user?.name || 'Customer'}</span>
                  {r.product?.name && <span className="text-[10px] text-stone-500">on {r.product.name}</span>}
                </div>
                {r.comment && <p className="text-xs text-stone-400 leading-relaxed">{r.comment}</p>}
                <p className="text-[10px] text-stone-600 mt-1.5">
                  Order {r.order?.orderNumber} · {new Date(r.createdAt).toLocaleDateString()}
                </p>
              </div>
              <div className="flex flex-col items-end gap-2 shrink-0">
                <span className={`px-2 py-0.5 rounded-full border text-[10px] font-black uppercase ${
                  r.isApproved ? 'bg-emerald-500/15 border-emerald-500/40 text-emerald-400' : 'bg-red-500/15 border-red-500/40 text-red-400'
                }`}>
                  {r.isApproved ? 'Visible' : 'Hidden'}
                </span>
                <button onClick={() => toggleApproval(r)} className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-stone-800 text-stone-300 hover:bg-stone-700">
                  {r.isApproved ? 'Hide' : 'Approve'}
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
