// ============================================================
// HungerPoint Web App — Auth Modal (Login / Register)
// ============================================================

'use client';

import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';

export function AuthModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const { login, register } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [phone, setPhone] = useState('+923009999999');
  const [password, setPassword] = useState('Customer@123456');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      if (mode === 'login') {
        await login(phone, password);
      } else {
        await register(name, phone, password, email);
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Authentication failed');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="w-full max-w-md bg-stone-900 border border-stone-800 rounded-3xl p-6 shadow-2xl text-stone-100 relative">
        
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-stone-400 hover:text-stone-100 text-sm p-1.5 hover:bg-stone-800 rounded-lg"
        >
          ✕
        </button>

        {/* Modal Header */}
        <div className="text-center mb-6">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-amber-500 to-orange-600 mx-auto flex items-center justify-center text-white font-black text-xl mb-3 shadow-lg shadow-orange-500/30">
            HP
          </div>
          <h3 className="text-xl font-black bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
            {mode === 'login' ? 'Welcome Back!' : 'Join HungerPoint'}
          </h3>
          <p className="text-xs text-stone-400 mt-1">
            {mode === 'login' ? 'Sign in to place orders and track delivery' : 'Create an account to get started'}
          </p>
        </div>

        {/* Mode Switcher */}
        <div className="flex bg-stone-800/80 p-1 rounded-xl mb-6 text-xs font-bold border border-stone-700/50">
          <button
            onClick={() => setMode('login')}
            className={`flex-1 py-2 rounded-lg transition-all ${
              mode === 'login' ? 'bg-amber-500 text-white shadow-md' : 'text-stone-400 hover:text-stone-200'
            }`}
          >
            Sign In
          </button>
          <button
            onClick={() => setMode('register')}
            className={`flex-1 py-2 rounded-lg transition-all ${
              mode === 'register' ? 'bg-amber-500 text-white shadow-md' : 'text-stone-400 hover:text-stone-200'
            }`}
          >
            Register
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-950/60 border border-red-800/60 text-red-300 text-xs rounded-xl text-center">
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {mode === 'register' && (
            <div>
              <label className="block text-stone-400 font-bold mb-1">Full Name</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Ahmed Khan"
                className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-stone-100 outline-none focus:border-amber-500"
              />
            </div>
          )}

          <div>
            <label className="block text-stone-400 font-bold mb-1">Mobile Phone Number</label>
            <input
              type="text"
              required
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+923009999999"
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-stone-100 outline-none focus:border-amber-500 font-mono"
            />
          </div>

          {mode === 'register' && (
            <div>
              <label className="block text-stone-400 font-bold mb-1">Email Address (Optional)</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="ahmed@gmail.com"
                className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-stone-100 outline-none focus:border-amber-500"
              />
            </div>
          )}

          <div>
            <label className="block text-stone-400 font-bold mb-1">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-stone-100 outline-none focus:border-amber-500"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-3 bg-gradient-to-r from-amber-500 via-orange-600 to-red-600 text-white font-extrabold rounded-xl shadow-lg shadow-orange-500/30 transition-all active:scale-95 disabled:opacity-50"
          >
            {submitting ? 'Please wait...' : mode === 'login' ? 'Sign In' : 'Create Account'}
          </button>
        </form>

        {/* Demo Accounts Quick Login */}
        <div className="mt-6 pt-4 border-t border-stone-800 text-[11px] text-stone-400">
          <p className="font-bold text-stone-300 mb-2">⚡ Quick Test Logins:</p>
          <div className="grid grid-cols-2 gap-1.5">
            <button
              onClick={() => { setPhone('+923009999999'); setPassword('Customer@123456'); setMode('login'); }}
              className="p-1.5 bg-stone-800 hover:bg-stone-700 rounded-lg text-amber-400 font-medium text-left truncate"
            >
              👤 Customer Account
            </button>
            <button
              onClick={() => { setPhone('+923000000001'); setPassword('Admin@123456'); setMode('login'); }}
              className="p-1.5 bg-stone-800 hover:bg-stone-700 rounded-lg text-amber-400 font-medium text-left truncate"
            >
              👑 Super Admin
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
