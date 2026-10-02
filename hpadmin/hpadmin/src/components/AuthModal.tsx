// ============================================================
// HungerPoint Web App — Auth Modal (Login / Register)
// ============================================================

import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';

export function AuthModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const { login, register } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      if (mode === 'login') {
        await login(email, password);
      } else {
        await register(name, email, phone, password);
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
            <label className="block text-stone-400 font-bold mb-1">Email</label>
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-stone-100 outline-none focus:border-amber-500"
            />
          </div>

          {mode === 'register' && (
            <div>
              <label className="block text-stone-400 font-bold mb-1">Mobile Number</label>
              <input
                type="tel"
                required
                autoComplete="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="03XX XXXXXXX"
                className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-stone-100 outline-none focus:border-amber-500"
              />
              <p className="text-[11px] text-stone-500 mt-1">Riders call this number when your order arrives.</p>
            </div>
          )}

          <div>
            <label className="block text-stone-400 font-bold mb-1">Password</label>
            <input
              type="password"
              required
              minLength={mode === 'register' ? 8 : undefined}
              autoComplete={mode === 'register' ? 'new-password' : 'current-password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder={mode === 'register' ? 'At least 8 characters' : '••••••••'}
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

      </div>
    </div>
  );
}
