import { lazy, Suspense } from 'react';
import { Routes, Route, Link } from 'react-router';
import StorefrontPage from './pages/StorefrontPage';
const OrderTrackingPage = lazy(() => import('./pages/OrderTrackingPage'));
const AdminPage = lazy(() => import('./pages/AdminPage'));
const KitchenPage = lazy(() => import('./pages/KitchenPage'));
const PosPage = lazy(() => import('./pages/PosPage'));
const BranchPage = lazy(() => import('./pages/BranchPage'));
const InventoryPage = lazy(() => import('./pages/InventoryPage'));
const LoyaltyPage = lazy(() => import('./pages/LoyaltyPage'));
const PromotionsPage = lazy(() => import('./pages/PromotionsPage'));
const ReportsPage = lazy(() => import('./pages/ReportsPage'));
const ReviewsPage = lazy(() => import('./pages/ReviewsPage'));
const RidersPage = lazy(() => import('./pages/RidersPage'));
const TablesPage = lazy(() => import('./pages/TablesPage'));
const SettingsPage = lazy(() => import('./pages/SettingsPage'));

function NotFoundPage() {
  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center p-6">
      <div className="text-center space-y-3">
        <p className="text-5xl font-black text-amber-400">404</p>
        <p className="text-sm text-stone-400">This page could not be found.</p>
        <Link to="/" className="inline-block text-xs font-bold text-amber-400 hover:underline">← Back to HungerPoint</Link>
      </div>
    </div>
  );
}

// Each staff page loads on demand, so customers opening the storefront
// don't download the whole admin console.
function PageLoader() {
  return (
    <div className="min-h-screen bg-stone-950 flex items-center justify-center">
      <div className="w-10 h-10 border-4 border-amber-500 border-t-transparent rounded-full animate-spin" />
    </div>
  );
}

export default function App() {
  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        <Route path="/" element={<StorefrontPage />} />
        <Route path="/orders/:id" element={<OrderTrackingPage />} />
        <Route path="/admin" element={<AdminPage />} />
        <Route path="/admin/kitchen" element={<KitchenPage />} />
        <Route path="/pos" element={<PosPage />} />
        <Route path="/branch" element={<BranchPage />} />
        <Route path="/inventory" element={<InventoryPage />} />
        <Route path="/loyalty" element={<LoyaltyPage />} />
        <Route path="/promotions" element={<PromotionsPage />} />
        <Route path="/reports" element={<ReportsPage />} />
        <Route path="/reviews" element={<ReviewsPage />} />
        <Route path="/riders" element={<RidersPage />} />
        <Route path="/tables" element={<TablesPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </Suspense>
  );
}
