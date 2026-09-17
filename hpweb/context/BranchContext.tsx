// ============================================================
// HungerPoint Web App — Branch Context
// ============================================================

'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { fetchApi } from '../lib/api';

export interface Branch {
  id: string;
  name: string;
  code: string;
  address: string;
  city?: string;
  isOpen: boolean;
}

interface BranchContextType {
  branches: Branch[];
  selectedBranchId: string | null;
  selectedBranch: Branch | null;
  setSelectedBranchId: (id: string) => void;
  loading: boolean;
}

const BranchContext = createContext<BranchContextType | undefined>(undefined);

export function BranchProvider({ children }: { children: React.ReactNode }) {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [selectedBranchId, setSelectedBranchIdState] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadBranches() {
      try {
        const res = await fetchApi('/branches');
        if (res.success) {
          setBranches(res.data);
          const savedId = localStorage.getItem('hp_selected_branch_id');
          const savedIsValid = savedId && res.data.some((b: Branch) => b.id === savedId);
          const defaultBranch = res.data.find((b: Branch) => b.isOpen) || res.data[0];
          setSelectedBranchIdState(savedIsValid ? savedId : defaultBranch?.id ?? null);
        }
      } catch (err) {
        console.error('Failed to load branches:', err);
      } finally {
        setLoading(false);
      }
    }
    loadBranches();
  }, []);

  const setSelectedBranchId = (id: string) => {
    setSelectedBranchIdState(id);
    localStorage.setItem('hp_selected_branch_id', id);
  };

  const selectedBranch = branches.find((b) => b.id === selectedBranchId) || null;

  return (
    <BranchContext.Provider value={{ branches, selectedBranchId, selectedBranch, setSelectedBranchId, loading }}>
      {children}
    </BranchContext.Provider>
  );
}

export function useBranch() {
  const context = useContext(BranchContext);
  if (!context) {
    throw new Error('useBranch must be used within a BranchProvider');
  }
  return context;
}
