// ============================================================
// HungerPoint Web App — Table Management (waiter app floor plan)
// Route: /tables
// ============================================================

import { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router';
import { fetchApi } from '../lib/api';
import { useBranch } from '../context/BranchContext';

const TABLES_ALLOWED_ROLES = ['ADMIN', 'BRANCH_MANAGER'];

const STATUS_STYLES: Record<string, string> = {
  AVAILABLE: 'bg-emerald-500/15 border-emerald-500/40 text-emerald-400',
  OCCUPIED: 'bg-amber-500/15 border-amber-500/40 text-amber-400',
  RESERVED: 'bg-sky-500/15 border-sky-500/40 text-sky-400',
};

const emptyForm = { branchId: '', number: '', floor: 'Ground Floor', capacity: '4' };

export default function TablesPage() {
  const navigate = useNavigate();
  const { branches } = useBranch();

  const [currentUser, setCurrentUser] = useState<any>(null);
  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [tables, setTables] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [branchFilter, setBranchFilter] = useState('');

  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [modalError, setModalError] = useState('');
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
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
    if (!token || !user || !TABLES_ALLOWED_ROLES.includes(user.role)) {
      navigate('/admin', { replace: true });
      return;
    }
    setCurrentUser(user);
    setAuthorized(true);
    setCheckingAuth(false);
  }, [navigate]);

  const loadTables = useCallback(async () => {
    setLoading(true);
    try {
      const qs = branchFilter ? `?branchId=${branchFilter}` : '';
      const res = await fetchApi(`/tables${qs}`);
      if (res.success) setTables(res.data);
    } catch (err) {
      console.error('Failed to load tables:', err);
    } finally {
      setLoading(false);
    }
  }, [branchFilter]);

  useEffect(() => {
    if (authorized) loadTables();
  }, [authorized, loadTables]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const isManager = currentUser?.role === 'BRANCH_MANAGER';

  const openCreate = () => {
    setModalError('');
    setEditingId(null);
    setForm({ ...emptyForm, branchId: isManager ? currentUser?.branchId || '' : branchFilter });
    setShowModal(true);
  };

  const openEdit = (t: any) => {
    setModalError('');
    setEditingId(t.id);
    setForm({ branchId: t.branchId, number: t.number, floor: t.floor, capacity: String(t.capacity) });
    setShowModal(true);
  };

  const closeModal = () => {
    setModalError('');
    setShowModal(false);
    setEditingId(null);
  };

  const handleSave = async () => {
    const editing = editingId !== null;
    const capacity = parseInt(form.capacity, 10);
    if (!form.number.trim() || !form.floor.trim() || (!editing && !form.branchId)) {
      setModalError('Branch, table number and floor are required');
      return;
    }
    if (!capacity || capacity < 1) {
      setModalError('Seats must be at least 1');
      return;
    }
    setModalError('');
    setSaving(true);
    try {
      const body: Record<string, unknown> = { number: form.number.trim(), floor: form.floor.trim(), capacity };
      if (!editing) body.branchId = form.branchId;
      const res = await fetchApi(editing ? `/tables/${editingId}` : '/tables', {
        method: editing ? 'PUT' : 'POST',
        body: JSON.stringify(body),
      });
      if (res.success) {
        showToast(editing ? 'Table updated' : 'Table created');
        closeModal();
        await loadTables();
      } else {
        setModalError(res.message || 'Failed to save table');
      }
    } catch (err: any) {
      setModalError(err.message || 'Failed to save table');
    } finally {
      setSaving(false);
    }
  };

  const handleRemove = async (t: any) => {
    if (!confirm(`Remove table ${t.number}? It will disappear from the waiter app.`)) return;
    try {
      const res = await fetchApi(`/tables/${t.id}`, { method: 'PUT', body: JSON.stringify({ isActive: false }) });
      if (res.success) {
        showToast('Table removed');
        await loadTables();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to remove table');
    }
  };

  const branchName = (id: string) => branches.find((b) => b.id === id)?.name || '—';

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center">
        <p className="text-stone-500 text-sm">Checking access...</p>
      </div>
    );
  }
  if (!authorized) return null;

  const inputCls = 'w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500';

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
            <Link to="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>🪑</span> Table Management</h1>
          </div>
          <div className="flex items-center gap-2">
            {!isManager && (
              <select
                value={branchFilter}
                onChange={(e) => setBranchFilter(e.target.value)}
                className="bg-stone-800 border border-stone-700 rounded-xl px-3 py-1.5 text-xs text-stone-200 outline-none"
              >
                <option value="">All branches</option>
                {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            )}
            <button onClick={openCreate} className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl">
              + New Table
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto p-6">
        <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
          {loading ? (
            <div className="text-center py-16 text-stone-500 text-sm">Loading tables...</div>
          ) : tables.length === 0 ? (
            <div className="text-center py-16 text-stone-500 text-sm">
              No tables yet. Add tables here — the waiter app shows nothing until its branch has tables.
            </div>
          ) : (
            <table className="w-full text-xs">
              <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                <tr>
                  <th className="text-left px-4 py-2.5 font-bold">Table</th>
                  <th className="text-left px-4 py-2.5 font-bold">Branch</th>
                  <th className="text-left px-4 py-2.5 font-bold">Floor</th>
                  <th className="text-left px-4 py-2.5 font-bold">Seats</th>
                  <th className="text-left px-4 py-2.5 font-bold">Status</th>
                  <th className="text-right px-4 py-2.5 font-bold">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-800">
                {tables.map((t) => (
                  <tr key={t.id} className="hover:bg-stone-800/30">
                    <td className="px-4 py-2.5 font-bold text-stone-100">{t.number}</td>
                    <td className="px-4 py-2.5 text-stone-400">{branchName(t.branchId)}</td>
                    <td className="px-4 py-2.5 text-stone-400">{t.floor}</td>
                    <td className="px-4 py-2.5 text-stone-400">{t.capacity}</td>
                    <td className="px-4 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full border text-[10px] font-black uppercase ${STATUS_STYLES[t.status] || STATUS_STYLES.AVAILABLE}`}>
                        {t.status}
                      </span>
                    </td>
                    <td className="px-4 py-2.5 text-right">
                      <button onClick={() => openEdit(t)} className="mr-1.5 px-2.5 py-1 rounded-lg text-[10px] font-bold bg-stone-800 text-amber-400 hover:bg-stone-700">
                        Edit
                      </button>
                      <button onClick={() => handleRemove(t)} className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-red-500/15 text-red-400 hover:bg-red-500/25">
                        Remove
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-3">
            <h3 className="text-base font-black text-stone-100">{editingId ? 'Edit Table' : 'New Table'}</h3>
            {modalError && (
              <div className="p-2.5 bg-red-950/60 border border-red-800/60 text-red-300 text-xs font-semibold rounded-xl">{modalError}</div>
            )}
            {!isManager && !editingId && (
              <select value={form.branchId} onChange={(e) => setForm({ ...form, branchId: e.target.value })} className={inputCls}>
                <option value="">Select branch...</option>
                {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            )}
            <input type="text" placeholder="Table number (e.g. T1, 12)" value={form.number} onChange={(e) => setForm({ ...form, number: e.target.value })} className={inputCls} />
            <input type="text" placeholder="Floor (e.g. Ground Floor)" value={form.floor} onChange={(e) => setForm({ ...form, floor: e.target.value })} className={inputCls} />
            <input type="number" min={1} placeholder="Seats" value={form.capacity} onChange={(e) => setForm({ ...form, capacity: e.target.value })} className={inputCls} />
            <div className="flex gap-2 pt-1">
              <button onClick={closeModal} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleSave} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Saving...' : editingId ? 'Save Changes' : 'Create Table'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
