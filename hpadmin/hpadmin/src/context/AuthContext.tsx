// ============================================================
// HungerPoint Web App — Auth Context
// ============================================================

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
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, phone: string, password: string) => Promise<void>;
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

  const login = async (email: string, password: string) => {
    const res = await fetchApi('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim(), password }),
    });

    if (res.success) {
      localStorage.setItem('hp_access_token', res.data.accessToken);
      if (res.data.refreshToken) {
        localStorage.setItem('hp_refresh_token', res.data.refreshToken);
      }
      localStorage.setItem('hp_user', JSON.stringify(res.data.user));
      setUser(res.data.user);
    }
  };

  const register = async (name: string, email: string, phone: string, password: string) => {
    const res = await fetchApi('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ name: name.trim(), email: email.trim(), phone: phone.trim(), password }),
    });

    if (res.success) {
      localStorage.setItem('hp_access_token', res.data.accessToken);
      if (res.data.refreshToken) {
        localStorage.setItem('hp_refresh_token', res.data.refreshToken);
      }
      localStorage.setItem('hp_user', JSON.stringify(res.data.user));
      setUser(res.data.user);
    }
  };

  const logout = () => {
    localStorage.removeItem('hp_access_token');
    localStorage.removeItem('hp_refresh_token');
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
