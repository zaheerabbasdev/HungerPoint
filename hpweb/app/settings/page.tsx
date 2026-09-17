// ============================================================
// HungerPoint Web App — Settings (Staff Accounts + System Config)
// Route: /settings
// ============================================================

'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';
import { useBranch } from '../../context/BranchContext';

const SETTINGS_ALLOWED_ROLES = ['SUPER_ADMIN', 'ADMIN'];
const STAFF_ROLES = ['ADMIN', 'BRANCH_MANAGER', 'BRANCH_STAFF', 'KITCHEN_STAFF'];

const emptyStaffForm = { name: '', phone: '', password: '', role: 'BRANCH_STAFF', branchId: '' };

export default function SettingsPage() {
  const router = useRouter();
  const { branches } = useBranch();

  const [authorized, setAuthorized] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);

  const [tab, setTab] = useState<'staff' | 'system'>('staff');
  const [staff, setStaff] = useState<any[]>([]);
  const [settings, setSettings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<string | null>(null);

  const [showStaffForm, setShowStaffForm] = useState(false);
  const [staffForm, setStaffForm] = useState(emptyStaffForm);
  const [saving, setSaving] = useState(false);

  const [settingEdits, setSettingEdits] = useState<Record<string, string>>({});

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
    if (!token || !user || !SETTINGS_ALLOWED_ROLES.includes(user.role)) {
      router.replace('/admin');
      return;
    }
    setAuthorized(true);
    setCheckingAuth(false);
  }, [router]);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [staffRes, settingsRes] = await Promise.all([
        fetchApi('/users'),
        fetchApi('/settings'),
      ]);
      if (staffRes.success) setStaff(staffRes.data);
      if (settingsRes.success) setSettings(settingsRes.data);
    } catch (err) {
      console.error('Failed to load settings data:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authorized) loadData();
  }, [authorized, loadData]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const handleCreateStaff = async () => {
    if (!staffForm.name.trim() || !staffForm.phone.trim() || !staffForm.password.trim()) return;
    setSaving(true);
    try {
      const res = await fetchApi('/users', {
        method: 'POST',
        body: JSON.stringify({
          name: staffForm.name.trim(),
          phone: staffForm.phone.trim(),
          password: staffForm.password,
          role: staffForm.role,
          branchId: staffForm.branchId || undefined,
        }),
      });
      if (res.success) {
        showToast('Staff account created');
        setShowStaffForm(false);
        setStaffForm(emptyStaffForm);
        await loadData();
      } else {
        showToast(res.message || 'Failed to create account');
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to create account');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (member: any) => {
    try {
      const res = await fetchApi(`/users/${member.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !member.isActive }),
      });
      if (res.success) {
        showToast(member.isActive ? 'Account deactivated' : 'Account activated');
        await loadData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update account');
    }
  };

  const handleSaveSetting = async (key: string, group: string) => {
    const value = settingEdits[key];
    if (value === undefined) return;
    try {
      const res = await fetchApi(`/settings/${key}`, {
        method: 'PUT',
        body: JSON.stringify({ value, group }),
      });
      if (res.success) {
        showToast(`${key} updated`);
        await loadData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update setting');
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

  const settingGroups = settings.reduce((acc: Record<string, any[]>, s) => {
    (acc[s.group] = acc[s.group] || []).push(s);
    return acc;
  }, {});

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100">
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-stone-900 border border-amber-500/40 text-amber-400 text-xs font-bold px-4 py-2.5 rounded-xl shadow-xl">
          {toast}
        </div>
      )}

      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 px-6 py-3.5 sticky top-0 z-30">
        <div className="max-w-5xl mx-auto flex items-center justify-between gap-4">
          <div>
            <Link href="/admin" className="text-xs text-amber-400 font-bold hover:underline">← Back to Admin Dashboard</Link>
            <h1 className="text-xl font-black text-stone-100 mt-0.5 flex items-center gap-2"><span>⚙️</span> Settings</h1>
          </div>
        </div>
      </header>

      <div className="max-w-5xl mx-auto p-6 space-y-6">
        <div className="flex gap-2">
          <button onClick={() => setTab('staff')} className={`px-4 py-2 rounded-xl text-xs font-extrabold transition-all ${tab === 'staff' ? 'bg-amber-500 text-stone-950' : 'bg-stone-800 text-stone-400 hover:text-stone-200'}`}>
            Staff Accounts
          </button>
          <button onClick={() => setTab('system')} className={`px-4 py-2 rounded-xl text-xs font-extrabold transition-all ${tab === 'system' ? 'bg-amber-500 text-stone-950' : 'bg-stone-800 text-stone-400 hover:text-stone-200'}`}>
            System Settings
          </button>
        </div>

        {tab === 'staff' && (
          <div className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
            <div className="p-4 border-b border-stone-800 flex justify-between items-center">
              <h2 className="text-sm font-extrabold text-stone-100">Staff Accounts</h2>
              <button onClick={() => setShowStaffForm(true)} className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl">
                + New Staff Account
              </button>
            </div>
            {loading ? (
              <div className="text-center py-16 text-stone-500 text-sm">Loading staff...</div>
            ) : staff.length === 0 ? (
              <div className="text-center py-16 text-stone-500 text-sm">No staff accounts yet.</div>
            ) : (
              <table className="w-full text-xs">
                <thead className="bg-stone-800/60 text-stone-400 uppercase tracking-wider">
                  <tr>
                    <th className="text-left px-4 py-2.5 font-bold">Name</th>
                    <th className="text-left px-4 py-2.5 font-bold">Role</th>
                    <th className="text-left px-4 py-2.5 font-bold">Branch</th>
                    <th className="text-left px-4 py-2.5 font-bold">Status</th>
                    <th className="text-right px-4 py-2.5 font-bold">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-800">
                  {staff.map((s) => (
                    <tr key={s.id} className="hover:bg-stone-800/30">
                      <td className="px-4 py-2.5">
                        <p className="font-bold text-stone-100">{s.name}</p>
                        <p className="text-stone-500">{s.phone}</p>
                      </td>
                      <td className="px-4 py-2.5 text-amber-400 font-bold">{s.role.replace('_', ' ')}</td>
                      <td className="px-4 py-2.5 text-stone-400">{s.branch?.name || '—'}</td>
                      <td className="px-4 py-2.5">
                        <span className={`px-2 py-0.5 rounded-full border text-[10px] font-black uppercase ${
                          s.isActive ? 'bg-emerald-500/15 border-emerald-500/40 text-emerald-400' : 'bg-stone-800 border-stone-700 text-stone-500'
                        }`}>
                          {s.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="px-4 py-2.5 text-right">
                        <button
                          onClick={() => handleToggleActive(s)}
                          className={`px-2.5 py-1 rounded-lg text-[10px] font-bold ${
                            s.isActive ? 'bg-red-500/15 text-red-400 hover:bg-red-500/25' : 'bg-emerald-500/15 text-emerald-400 hover:bg-emerald-500/25'
                          }`}
                        >
                          {s.isActive ? 'Deactivate' : 'Activate'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}

        {tab === 'system' && (
          <div className="space-y-6">
            {Object.entries(settingGroups).map(([group, items]) => (
              <div key={group} className="bg-stone-900 border border-stone-800 rounded-2xl overflow-hidden">
                <div className="p-4 border-b border-stone-800">
                  <h2 className="text-sm font-extrabold text-stone-100 capitalize">{group}</h2>
                </div>
                <div className="p-4 space-y-3">
                  {items.map((s: any) => (
                    <div key={s.key} className="flex items-center gap-3">
                      <label className="text-xs font-bold text-stone-400 w-48 shrink-0">{s.key.replace(/_/g, ' ')}</label>
                      <input
                        type="text"
                        defaultValue={s.value}
                        onChange={(e) => setSettingEdits({ ...settingEdits, [s.key]: e.target.value })}
                        className="flex-1 bg-stone-800 border border-stone-700 rounded-xl px-3 py-2 text-xs text-stone-100 outline-none focus:border-amber-500"
                      />
                      <button
                        onClick={() => handleSaveSetting(s.key, s.group)}
                        className="px-3 py-2 bg-stone-800 hover:bg-stone-700 text-amber-400 text-xs font-bold rounded-xl"
                      >
                        Save
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Create Staff Modal */}
      {showStaffForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-sm bg-stone-900 border border-stone-800 rounded-3xl p-5 space-y-3">
            <h3 className="text-base font-black text-stone-100">New Staff Account</h3>
            <input type="text" placeholder="Full name" value={staffForm.name} onChange={(e) => setStaffForm({ ...staffForm, name: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="text" placeholder="Phone number" value={staffForm.phone} onChange={(e) => setStaffForm({ ...staffForm, phone: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <input type="password" placeholder="Temporary password" value={staffForm.password} onChange={(e) => setStaffForm({ ...staffForm, password: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500" />
            <select value={staffForm.role} onChange={(e) => setStaffForm({ ...staffForm, role: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none">
              {STAFF_ROLES.map((r) => <option key={r} value={r}>{r.replace('_', ' ')}</option>)}
            </select>
            <select value={staffForm.branchId} onChange={(e) => setStaffForm({ ...staffForm, branchId: e.target.value })}
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none">
              <option value="">No branch (HQ / all-branch access)</option>
              {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>
            <div className="flex gap-2 pt-1">
              <button onClick={() => setShowStaffForm(false)} className="flex-1 py-2.5 text-xs font-bold text-stone-400 hover:text-stone-200">Cancel</button>
              <button onClick={handleCreateStaff} disabled={saving} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-600 text-stone-950 text-xs font-black rounded-xl disabled:opacity-50">
                {saving ? 'Creating...' : 'Create Account'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
