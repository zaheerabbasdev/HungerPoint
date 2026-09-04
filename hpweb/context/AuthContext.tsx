// ============================================================
// HungerPoint Web App — Auth Context
// ============================================================

'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { fetchApi } from '../lib/api';

interface User {
  id: string;
  name: string;
  phone: string;
  email?: string;
  role: string;
  branchId?: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (phone: string, password: string) => Promise<void>;
  register: (name: string, phone: string, password: string, email?: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('hp_access_token');
    const savedUser = localStorage.getItem('hp_user');

    if (token && savedUser) {
      try {
        setUser(JSON.parse(savedUser));
      } catch (e) {
        console.error(e);
      }
    }
    setLoading(false);
  }, []);

  const login = async (phone: string, password: string) => {
    const res = await fetchApi('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ phone, password }),
    });

    if (res.success) {
      localStorage.setItem('hp_access_token', res.data.accessToken);
      localStorage.setItem('hp_user', JSON.stringify(res.data.user));
      setUser(res.data.user);
    }
  };

  const register = async (name: string, phone: string, password: string, email?: string) => {
    const res = await fetchApi('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ name, phone, password, email }),
    });

    if (res.success) {
      localStorage.setItem('hp_access_token', res.data.accessToken);
      localStorage.setItem('hp_user', JSON.stringify(res.data.user));
      setUser(res.data.user);
    }
  };

  const logout = () => {
    localStorage.removeItem('hp_access_token');
    localStorage.removeItem('hp_user');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
