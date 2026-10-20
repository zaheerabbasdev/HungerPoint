// ============================================================
// HungerPoint Web App — Customer shell (header, cart drawer, sign-in)
// ============================================================

import { useState, type ReactNode } from 'react';
import { Navbar } from './Navbar';
import { CartDrawer } from './CartDrawer';
import { AuthModal } from './AuthModal';

export function CustomerShell({ children, openAuth }: { children: (openAuth: () => void) => ReactNode; openAuth?: boolean }) {
  const [isAuthOpen, setIsAuthOpen] = useState(!!openAuth);
  const open = () => setIsAuthOpen(true);

  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 font-sans selection:bg-amber-500 selection:text-white">
      <Navbar onOpenAuth={open} />
      {children(open)}
      <CartDrawer onRequireAuth={open} />
      <AuthModal isOpen={isAuthOpen} onClose={() => setIsAuthOpen(false)} />
    </div>
  );
}
