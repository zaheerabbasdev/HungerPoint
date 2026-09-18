// ============================================================
// HungerPoint Web App — Module 12: Admin Operations & Menu Portal
// Route: /admin
// ============================================================

'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { fetchApi } from '../../lib/api';
import {
  Utensils,
  Layers,
  ShoppingBag,
  Store,
  Plus,
  Edit2,
  Trash2,
  Check,
  X,
  Search,
  RefreshCw,
  Eye,
  EyeOff,
  LogOut,
  TrendingUp,
  AlertCircle,
  Clock,
  MapPin,
  ChevronRight,
  ShieldCheck,
  Phone,
  Lock,
  Upload,
  ImageIcon,
} from 'lucide-react';

interface Category {
  id: string;
  name: string;
  description?: string;
  image?: string;
  sortOrder: number;
  isActive: boolean;
  products?: any[];
}

interface Variant {
  id?: string;
  name: string;
  price: number;
  isDefault?: boolean;
}

interface Addon {
  id: string;
  name: string;
  price: number;
  isActive: boolean;
}

interface Product {
  id: string;
  categoryId: string;
  name: string;
  description?: string;
  image?: string;
  basePrice: number;
  sortOrder: number;
  isActive: boolean;
  category?: { id: string; name: string };
  variants?: Variant[];
  addons?: { addon: Addon }[];
}

interface Order {
  id: string;
  orderNumber: string;
  source?: string;
  total: number;
  status: string;
  type?: string;
  branchId?: string;
  paymentMethod: string;
  createdAt: string;
  customer?: { user?: { name: string; phone: string } };
  branch?: { name: string };
  items?: any[];
  delivery?: { id: string; status: string; rider?: { user?: { name: string; phone: string } } } | null;
}

interface RiderOption {
  id: string;
  status: string;
  branchId?: string;
  user?: { name: string; phone: string };
}

interface Branch {
  id: string;
  name: string;
  code: string;
  address: string;
  city?: string;
  area?: string;
  latitude?: number | string;
  longitude?: number | string;
  phone?: string;
  deliveryRadius: number | string;
  isOpen: boolean;
  isActive: boolean;
}

export default function AdminPortalPage() {
  // Auth state
  const [authToken, setAuthToken] = useState<string | null>(null);
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [loginIdentifier, setLoginIdentifier] = useState('admin@hungerpoint.pk');
  const [loginPassword, setLoginPassword] = useState('Admin@123456');
  const [loginError, setLoginError] = useState('');
  const [isSubmittingLogin, setIsSubmittingLogin] = useState(false);

  // Active Top Navigation Tab
  const [activeTab, setActiveTab] = useState<'menu' | 'dashboard' | 'orders' | 'branches'>('menu');
  // Active Menu Subtab
  const [menuSubTab, setMenuSubTab] = useState<'categories' | 'products' | 'addons'>('categories');

  // Live Data States
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [addons, setAddons] = useState<Addon[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [riders, setRiders] = useState<RiderOption[]>([]);
  const [assigningOrderId, setAssigningOrderId] = useState<string | null>(null);
  const [confirmingOrderId, setConfirmingOrderId] = useState<string | null>(null);
  const [selectedRiderByOrder, setSelectedRiderByOrder] = useState<Record<string, string>>({});
  const [overview, setOverview] = useState<any>(null);
  const [dataLoading, setDataLoading] = useState(false);

  // Search & Filter States
  const [productSearch, setProductSearch] = useState('');
  const [selectedCategoryFilter, setSelectedCategoryFilter] = useState('ALL');
  const [orderSourceFilter, setOrderSourceFilter] = useState('ALL');

  // Modals States
  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [categoryForm, setCategoryForm] = useState<{
    name: string;
    description: string;
    image: string;
    sortOrder: number | string;
    isActive: boolean;
  }>({
    name: '',
    description: '',
    image: '',
    sortOrder: 0,
    isActive: true,
  });

  const [showProductModal, setShowProductModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [productForm, setProductForm] = useState<{
    categoryId: string;
    name: string;
    description: string;
    image: string;
    basePrice: number | string;
    sortOrder: number | string;
    isActive: boolean;
    variants: { name: string; price: number | string; isDefault: boolean }[];
    addonIds: string[];
  }>({
    categoryId: '',
    name: '',
    description: '',
    image: '',
    basePrice: 0,
    sortOrder: 0,
    isActive: true,
    variants: [] as { name: string; price: number | string; isDefault: boolean }[],
    addonIds: [] as string[],
  });

  const [showAddonModal, setShowAddonModal] = useState(false);
  const [addonForm, setAddonForm] = useState<{
    name: string;
    price: number | string;
  }>({
    name: '',
    price: 0,
  });

  const [showBranchModal, setShowBranchModal] = useState(false);
  const [editingBranch, setEditingBranch] = useState<Branch | null>(null);
  const [branchForm, setBranchForm] = useState<{
    name: string;
    code: string;
    address: string;
    city: string;
    area: string;
    latitude: number | string;
    longitude: number | string;
    phone: string;
    deliveryRadius: number | string;
    isOpen: boolean;
    isActive: boolean;
  }>({
    name: '',
    code: '',
    address: '',
    city: 'Islamabad',
    area: '',
    latitude: 33.6844,
    longitude: 73.0039,
    phone: '+923001234567',
    deliveryRadius: 8,
    isOpen: true,
    isActive: true,
  });
  const [uploadingImage, setUploadingImage] = useState(false);

  // Action status toast
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 3500);
  };

  // ─── 1. Check Session & Initialize ───────────────────────────
  useEffect(() => {
    const token = localStorage.getItem('hp_access_token');
    const userStr = localStorage.getItem('hp_user');
    if (token && userStr) {
      try {
        const u = JSON.parse(userStr);
        setAuthToken(token);
        setCurrentUser(u);
        // Validate token with backend
        fetchApi('/auth/me').catch(() => {
          localStorage.removeItem('hp_access_token');
          localStorage.removeItem('hp_refresh_token');
          localStorage.removeItem('hp_user');
          setAuthToken(null);
          setCurrentUser(null);
          setLoginError('Session expired. Please log in again.');
        });
      } catch {
        localStorage.removeItem('hp_access_token');
        localStorage.removeItem('hp_refresh_token');
        localStorage.removeItem('hp_user');
      }
    }
    setAuthLoading(false);

    const handleAuthExpired = () => {
      setAuthToken(null);
      setCurrentUser(null);
      setLoginError('Your session has expired. Please sign in again.');
    };
    window.addEventListener('hp_auth_expired', handleAuthExpired);
    return () => window.removeEventListener('hp_auth_expired', handleAuthExpired);
  }, []);

  // ─── 2. Fetch Data when authenticated ────────────────────────
  const loadAllData = async () => {
    if (!authToken) return;
    setDataLoading(true);
    try {
      const [catsRes, prodsRes, addsRes, ordsRes, bransRes, ovRes, ridersRes] = await Promise.allSettled([
        fetchApi('/categories?includeInactive=true'),
        fetchApi('/products?includeInactive=true'),
        fetchApi('/products/addons/all'),
        fetchApi('/orders'),
        fetchApi('/branches'),
        fetchApi('/reports/overview'),
        fetchApi('/riders'),
      ]);

      if (catsRes.status === 'fulfilled' && catsRes.value.success) {
        setCategories(catsRes.value.data || []);
      }
      if (prodsRes.status === 'fulfilled' && prodsRes.value.success) {
        setProducts(prodsRes.value.data || []);
      }
      if (addsRes.status === 'fulfilled' && addsRes.value.success) {
        setAddons(addsRes.value.data || []);
      }
      if (ordsRes.status === 'fulfilled' && ordsRes.value.success) {
        setOrders(ordsRes.value.orders || ordsRes.value.data || []);
      }
      if (bransRes.status === 'fulfilled' && bransRes.value.success) {
        setBranches(bransRes.value.data || []);
      }
      if (ovRes.status === 'fulfilled' && ovRes.value.success) {
        setOverview(ovRes.value.data || null);
      }
      if (ridersRes.status === 'fulfilled' && ridersRes.value.success) {
        setRiders(ridersRes.value.data || []);
      }
    } catch (e: any) {
      console.error('Data load error:', e);
      showToast(e.message || 'Error syncing data from backend', 'error');
    } finally {
      setDataLoading(false);
    }
  };

  useEffect(() => {
    if (authToken) {
      loadAllData();
    }
  }, [authToken]);

  // ─── 3. Auth Actions ─────────────────────────────────────────
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmittingLogin(true);
    setLoginError('');

    try {
      const isEmail = loginIdentifier.includes('@');
      const body = isEmail
        ? { email: loginIdentifier, password: loginPassword }
        : { phone: loginIdentifier, password: loginPassword };

      const res = await fetchApi('/auth/login', {
        method: 'POST',
        body: JSON.stringify(body),
      });

      if (res.success && res.data) {
        const { user, accessToken, refreshToken } = res.data;
        if (user.role !== 'SUPER_ADMIN' && user.role !== 'ADMIN' && user.role !== 'BRANCH_MANAGER') {
          throw new Error('Access denied: You need administrative privileges to access this console.');
        }
        localStorage.setItem('hp_access_token', accessToken);
        if (refreshToken) {
          localStorage.setItem('hp_refresh_token', refreshToken);
        }
        localStorage.setItem('hp_user', JSON.stringify(user));
        setAuthToken(accessToken);
        setCurrentUser(user);
        showToast(`Welcome back, ${user.name}!`);
      } else {
        throw new Error(res.message || 'Login failed');
      }
    } catch (err: any) {
      setLoginError(err.message || 'Authentication failed');
    } finally {
      setIsSubmittingLogin(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('hp_access_token');
    localStorage.removeItem('hp_refresh_token');
    localStorage.removeItem('hp_user');
    setAuthToken(null);
    setCurrentUser(null);
    showToast('Logged out successfully');
  };

  // ─── 4. Category CRUD ────────────────────────────────────────
  const openCategoryModal = (cat?: Category) => {
    if (cat) {
      setEditingCategory(cat);
      setCategoryForm({
        name: cat.name,
        description: cat.description || '',
        image: cat.image || '',
        sortOrder: cat.sortOrder ?? 0,
        isActive: cat.isActive,
      });
    } else {
      setEditingCategory(null);
      setCategoryForm({
        name: '',
        description: '',
        image: '',
        sortOrder: categories.length + 1,
        isActive: true,
      });
    }
    setShowCategoryModal(true);
  };

  const handleSaveCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!categoryForm.name.trim()) {
      showToast('Category name is required', 'error');
      return;
    }

    const payload = {
      name: categoryForm.name.trim(),
      description: categoryForm.description.trim(),
      image: categoryForm.image,
      sortOrder:
        typeof categoryForm.sortOrder === 'string'
          ? parseInt(categoryForm.sortOrder, 10) || 0
          : categoryForm.sortOrder,
      isActive: categoryForm.isActive,
    };

    try {
      if (editingCategory) {
        // Update
        const res = await fetchApi(`/categories/${editingCategory.id}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        if (res.success) {
          showToast(`Category "${categoryForm.name}" updated successfully`);
        }
      } else {
        // Create
        const res = await fetchApi('/categories', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        if (res.success) {
          showToast(`Category "${categoryForm.name}" created successfully`);
        }
      }
      setShowCategoryModal(false);
      loadAllData();
    } catch (err: any) {
      showToast(err.message || 'Failed to save category', 'error');
    }
  };

  const handleToggleCategoryActive = async (cat: Category) => {
    try {
      const res = await fetchApi(`/categories/${cat.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !cat.isActive }),
      });
      if (res.success) {
        showToast(`Category marked ${!cat.isActive ? 'Active' : 'Inactive'}`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update category status', 'error');
    }
  };

  const handleDeleteCategory = async (cat: Category) => {
    if (!confirm(`Are you sure you want to delete category "${cat.name}"?`)) return;
    try {
      const res = await fetchApi(`/categories/${cat.id}`, {
        method: 'DELETE',
      });
      if (res.success) {
        showToast(`Category "${cat.name}" deleted`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to delete category', 'error');
    }
  };

  // ─── 5. Product CRUD ─────────────────────────────────────────
  const openProductModal = (prod?: Product) => {
    if (prod) {
      setEditingProduct(prod);
      const existingAddonIds = (prod.addons || []).map((a) => a.addon?.id).filter(Boolean);
      setProductForm({
        categoryId: prod.categoryId,
        name: prod.name,
        description: prod.description || '',
        image: prod.image || '',
        basePrice: Number(prod.basePrice),
        sortOrder: prod.sortOrder || 0,
        isActive: prod.isActive,
        variants: (prod.variants || []).map((v) => ({
          name: v.name,
          price: Number(v.price),
          isDefault: v.isDefault || false,
        })),
        addonIds: existingAddonIds,
      });
    } else {
      setEditingProduct(null);
      setProductForm({
        categoryId: categories[0]?.id || '',
        name: '',
        description: '',
        image: '',
        basePrice: 500,
        sortOrder: products.length + 1,
        isActive: true,
        variants: [],
        addonIds: [],
      });
    }
    setShowProductModal(true);
  };

  const handleSaveProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!productForm.name.trim() || !productForm.categoryId) {
      showToast('Name and Category are required', 'error');
      return;
    }

    const payload = {
      ...productForm,
      basePrice: Number(productForm.basePrice) || 0,
      variants: productForm.variants.map((v) => ({
        ...v,
        price: Number(v.price) || 0,
      })),
    };

    try {
      if (editingProduct) {
        // Update product
        const res = await fetchApi(`/products/${editingProduct.id}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        if (res.success) {
          showToast(`Product "${productForm.name}" updated successfully`);
        }
      } else {
        // Create product
        const res = await fetchApi('/products', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        if (res.success) {
          showToast(`Product "${productForm.name}" added to menu!`);
        }
      }
      setShowProductModal(false);
      loadAllData();
    } catch (err: any) {
      showToast(err.message || 'Failed to save product', 'error');
    }
  };

  const handleToggleProductActive = async (prod: Product) => {
    try {
      const res = await fetchApi(`/products/${prod.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !prod.isActive }),
      });
      if (res.success) {
        showToast(`"${prod.name}" marked ${!prod.isActive ? 'Available' : 'Sold Out'}`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update availability', 'error');
    }
  };

  const handleDeleteProduct = async (prod: Product) => {
    if (!confirm(`Are you sure you want to delete "${prod.name}" from the menu?`)) return;
    try {
      const res = await fetchApi(`/products/${prod.id}`, {
        method: 'DELETE',
      });
      if (res.success) {
        showToast(`"${prod.name}" removed from menu`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to delete product', 'error');
    }
  };

  // ─── 6. Addons CRUD ──────────────────────────────────────────
  const handleCreateAddon = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!addonForm.name.trim()) return;
    try {
      const res = await fetchApi('/products/addons', {
        method: 'POST',
        body: JSON.stringify({
          name: addonForm.name.trim(),
          price: Number(addonForm.price) || 0,
        }),
      });
      if (res.success) {
        showToast(`Add-on "${addonForm.name}" created`);
        setShowAddonModal(false);
        setAddonForm({ name: '', price: 0 });
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to create add-on', 'error');
    }
  };

  const handleDeleteAddon = async (addon: Addon) => {
    if (!confirm(`Delete add-on "${addon.name}"?`)) return;
    try {
      const res = await fetchApi(`/products/addons/${addon.id}`, {
        method: 'DELETE',
      });
      if (res.success) {
        showToast(`Add-on "${addon.name}" deleted`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to delete add-on', 'error');
    }
  };

  // ─── 7. Order Status Update ──────────────────────────────────
  const handleUpdateOrderStatus = async (orderId: string, status: string) => {
    try {
      const res = await fetchApi(`/orders/${orderId}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      if (res.success) {
        showToast(`Order status updated to ${status}`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update order status', 'error');
    }
  };

  const handleConfirmOrder = async (orderId: string) => {
    setConfirmingOrderId(orderId);
    try {
      const res = await fetchApi(`/orders/${orderId}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status: 'CONFIRMED' }),
      });
      if (res.success) {
        showToast('Order confirmed — sent to kitchen');
        loadAllData();
      } else {
        showToast(res.message || 'Failed to confirm order', 'error');
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to confirm order', 'error');
    } finally {
      setConfirmingOrderId(null);
    }
  };

  const handleAssignRider = async (orderId: string) => {
    const riderId = selectedRiderByOrder[orderId];
    if (!riderId) {
      showToast('Select a rider first', 'error');
      return;
    }
    setAssigningOrderId(orderId);
    try {
      const res = await fetchApi('/riders/assign', {
        method: 'POST',
        body: JSON.stringify({ orderId, riderId }),
      });
      if (res.success) {
        showToast('Rider assigned — order moved to ASSIGNED');
        loadAllData();
      } else {
        showToast(res.message || 'Failed to assign rider', 'error');
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to assign rider', 'error');
    } finally {
      setAssigningOrderId(null);
    }
  };

  // ─── 8. Image Upload Handler ──────────────────────────────────
  const handleFileUpload = async (file: File, onSuccess: (url: string) => void) => {
    if (!file) return;
    setUploadingImage(true);
    try {
      const formData = new FormData();
      formData.append('image', file);
      const token = typeof window !== 'undefined' ? localStorage.getItem('hp_access_token') : null;
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api/v1';

      let uploadedUrl = '';
      try {
        const res = await fetch(`${apiUrl}/upload`, {
          method: 'POST',
          headers: {
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
          body: formData,
        });
        const data = await res.json();
        if (res.ok && data.success && data.data?.url) {
          uploadedUrl = data.data.url;
        }
      } catch (uploadErr) {
        console.warn('Backend upload failed, converting to local DataURL', uploadErr);
      }

      if (!uploadedUrl) {
        const reader = new FileReader();
        uploadedUrl = await new Promise<string>((resolve, reject) => {
          reader.onload = () => resolve(reader.result as string);
          reader.onerror = reject;
          reader.readAsDataURL(file);
        });
      }

      onSuccess(uploadedUrl);
      showToast('Image uploaded successfully!');
    } catch (err: any) {
      showToast(err.message || 'Failed to process local image', 'error');
    } finally {
      setUploadingImage(false);
    }
  };

  // ─── 9. Branch CRUD ──────────────────────────────────────────
  const openBranchModal = (branch?: Branch) => {
    if (branch) {
      setEditingBranch(branch);
      setBranchForm({
        name: branch.name,
        code: branch.code,
        address: branch.address,
        city: branch.city || 'Islamabad',
        area: branch.area || '',
        latitude: Number(branch.latitude) || 33.6844,
        longitude: Number(branch.longitude) || 73.0039,
        phone: branch.phone || '',
        deliveryRadius: Number(branch.deliveryRadius) || 5,
        isOpen: branch.isOpen ?? true,
        isActive: branch.isActive ?? true,
      });
    } else {
      setEditingBranch(null);
      setBranchForm({
        name: '',
        code: `HP-B${Math.floor(100 + Math.random() * 900)}`,
        address: '',
        city: 'Islamabad',
        area: '',
        latitude: Number((33.68 + Math.random() * 0.05).toFixed(4)),
        longitude: Number((73.00 + Math.random() * 0.06).toFixed(4)),
        phone: '+923001234567',
        deliveryRadius: 8,
        isOpen: true,
        isActive: true,
      });
    }
    setShowBranchModal(true);
  };

  const handleSaveBranch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!branchForm.name.trim() || !branchForm.code.trim() || !branchForm.address.trim()) {
      showToast('Branch name, code, and address are required', 'error');
      return;
    }

    const payload = {
      name: branchForm.name.trim(),
      code: branchForm.code.trim(),
      address: branchForm.address.trim(),
      city: branchForm.city.trim() || 'Islamabad',
      area: branchForm.area?.trim() || undefined,
      latitude: Number(branchForm.latitude) || 33.6844,
      longitude: Number(branchForm.longitude) || 73.0039,
      phone: branchForm.phone?.trim() || undefined,
      deliveryRadius: Number(branchForm.deliveryRadius) || 5,
      isOpen: Boolean(branchForm.isOpen),
      isActive: Boolean(branchForm.isActive),
    };

    try {
      if (editingBranch) {
        const res = await fetchApi(`/branches/${editingBranch.id}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        if (res.success) {
          showToast(`Branch "${branchForm.name}" updated successfully!`);
          setShowBranchModal(false);
          setEditingBranch(null);
          loadAllData();
        }
      } else {
        const res = await fetchApi('/branches', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        if (res.success) {
          showToast(`Branch "${branchForm.name}" created successfully!`);
          setShowBranchModal(false);
          loadAllData();
        }
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to save branch', 'error');
    }
  };

  const handleDeleteBranch = async (branch: Branch) => {
    if (!confirm(`Are you sure you want to delete branch "${branch.name}"? This action cannot be undone.`)) {
      return;
    }
    try {
      const res = await fetchApi(`/branches/${branch.id}`, {
        method: 'DELETE',
      });
      if (res.success) {
        showToast(`Branch "${branch.name}" deleted successfully!`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to delete branch', 'error');
    }
  };

  const handleToggleBranchOpen = async (branch: Branch) => {
    try {
      const res = await fetchApi(`/branches/${branch.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isOpen: !branch.isOpen }),
      });
      if (res.success) {
        showToast(`Branch marked ${!branch.isOpen ? 'Open' : 'Closed'}`);
        loadAllData();
      }
    } catch (err: any) {
      showToast(err.message || 'Failed to update branch status', 'error');
    }
  };

  // Filtered Products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchSearch =
        p.name.toLowerCase().includes(productSearch.toLowerCase()) ||
        (p.description && p.description.toLowerCase().includes(productSearch.toLowerCase()));
      const matchCat = selectedCategoryFilter === 'ALL' || p.categoryId === selectedCategoryFilter;
      return matchSearch && matchCat;
    });
  }, [products, productSearch, selectedCategoryFilter]);

  // Filtered Orders
  const filteredOrders = useMemo(() => {
    return orders.filter((o) => {
      if (orderSourceFilter === 'ALL') return true;
      return (o.source || 'MOBILE_APP').toUpperCase() === orderSourceFilter;
    });
  }, [orders, orderSourceFilter]);

  // ─── Render Authentication Modal / Wall ──────────────────────
  if (authLoading) {
    return (
      <div className="min-h-screen bg-stone-950 flex items-center justify-center text-stone-100">
        <RefreshCw className="w-8 h-8 animate-spin text-amber-500" />
      </div>
    );
  }

  if (!authToken || !currentUser) {
    return (
      <div className="min-h-screen bg-stone-950 text-stone-100 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-stone-900 border border-stone-800 rounded-3xl p-8 shadow-2xl space-y-6">
          <div className="text-center space-y-2">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-400 mb-2">
              <ShieldCheck className="w-8 h-8" />
            </div>
            <h1 className="text-2xl font-black bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              HungerPoint Admin Console
            </h1>
            <p className="text-xs text-stone-400">
              Module 12: Operations, Live Menu Sync & Storefront Management
            </p>
          </div>

          {loginError && (
            <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400 text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{loginError}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-stone-400 uppercase tracking-wider mb-1.5">
                Admin Phone or Email
              </label>
              <div className="relative">
                <input
                  type="text"
                  value={loginIdentifier}
                  onChange={(e) => setLoginIdentifier(e.target.value)}
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-3 text-sm text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500 transition-colors"
                  placeholder="admin@hungerpoint.pk or +923000000001"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-stone-400 uppercase tracking-wider mb-1.5">
                Password
              </label>
              <div className="relative">
                <input
                  type="password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-3 text-sm text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500 transition-colors"
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmittingLogin}
              className="w-full py-3.5 px-4 bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-400 hover:to-orange-500 text-stone-950 font-black rounded-xl text-sm transition-all shadow-lg shadow-orange-500/20 disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isSubmittingLogin ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  <span>Authenticating...</span>
                </>
              ) : (
                <span>Access Operations Portal</span>
              )}
            </button>
          </form>

          <div className="pt-4 border-t border-stone-800 text-center">
            <button
              type="button"
              onClick={() => {
                setLoginIdentifier('admin@hungerpoint.pk');
                setLoginPassword('Admin@123456');
              }}
              className="text-xs text-stone-500 hover:text-amber-400 underline transition-colors"
            >
              Prefill Seed Super Admin Credentials
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─── Main Admin Console UI ──────────────────────────────────
  return (
    <div className="min-h-screen bg-stone-950 text-stone-100 flex flex-col font-sans">
      {/* Toast alert */}
      {toastMessage && (
        <div
          className={`fixed bottom-6 right-6 z-50 px-5 py-3 rounded-2xl shadow-2xl border text-xs font-bold flex items-center gap-2 transition-all transform animate-in slide-in-from-bottom-5 ${
            toastMessage.type === 'error'
              ? 'bg-red-950/90 border-red-500/40 text-red-300'
              : 'bg-stone-900/95 border-amber-500/50 text-amber-300 shadow-orange-500/10'
          }`}
        >
          {toastMessage.type === 'error' ? (
            <AlertCircle className="w-4 h-4 text-red-400" />
          ) : (
            <Check className="w-4 h-4 text-amber-400" />
          )}
          <span>{toastMessage.text}</span>
        </div>
      )}

      {/* Top Navbar */}
      <header className="bg-stone-900/90 backdrop-blur-md border-b border-stone-800 sticky top-0 z-40 px-6 py-3.5">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Link href="/" className="flex items-center gap-2 group">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center font-black text-stone-950 text-lg shadow-md shadow-orange-500/20">
                HP
              </div>
              <div className="hidden sm:block">
                <span className="font-black text-base text-stone-100 group-hover:text-amber-400 transition-colors">
                  HungerPoint
                </span>
                <span className="text-[10px] block font-bold text-amber-500 uppercase tracking-widest -mt-1">
                  Admin Console
                </span>
              </div>
            </Link>

            <div className="hidden md:flex items-center gap-2 pl-4 border-l border-stone-800 text-xs">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span className="text-stone-400 font-medium">Live Database Connected</span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/branch"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>🏬 Branch</span>
            </Link>

            <Link
              href="/pos"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>🧾 POS</span>
            </Link>

            <Link
              href="/inventory"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>📦 Inventory</span>
            </Link>

            <Link
              href="/riders"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>🛵 Riders</span>
            </Link>

            <Link
              href="/promotions"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>🎟️ Promotions</span>
            </Link>

            <Link
              href="/reports"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>📊 Reports</span>
            </Link>

            <Link
              href="/loyalty"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>⭐ Loyalty</span>
            </Link>

            <Link
              href="/reviews"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>💬 Reviews</span>
            </Link>

            <Link
              href="/settings"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>⚙️ Settings</span>
            </Link>

            <Link
              href="/admin/kitchen"
              className="px-3.5 py-1.5 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 text-amber-400 font-bold text-xs rounded-xl transition-all hidden sm:flex items-center gap-1.5"
            >
              <span>🍳 KDU Kitchen Display</span>
            </Link>

            <button
              onClick={loadAllData}
              disabled={dataLoading}
              className="p-2 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-xl transition-colors disabled:opacity-50"
              title="Sync Data"
            >
              <RefreshCw className={`w-4 h-4 ${dataLoading ? 'animate-spin text-amber-400' : ''}`} />
            </button>

            <div className="flex items-center gap-2.5 pl-3 border-l border-stone-800">
              <div className="text-right hidden sm:block">
                <p className="text-xs font-bold text-stone-200">{currentUser?.name || 'Administrator'}</p>
                <p className="text-[10px] font-black text-amber-500 uppercase tracking-wider">
                  {currentUser?.role || 'SUPER_ADMIN'}
                </p>
              </div>
              <button
                onClick={handleLogout}
                className="p-2 bg-stone-800 hover:bg-red-500/20 hover:text-red-400 text-stone-400 rounded-xl transition-colors"
                title="Logout"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Workspace Navigation Tabs */}
      <div className="border-b border-stone-800 bg-stone-900/40">
        <div className="max-w-7xl mx-auto px-6 flex space-x-1 sm:space-x-4 overflow-x-auto py-2">
          <button
            onClick={() => setActiveTab('menu')}
            className={`px-4 py-2.5 rounded-xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
              activeTab === 'menu'
                ? 'bg-amber-500 text-stone-950 shadow-md shadow-orange-500/20'
                : 'text-stone-400 hover:text-stone-200 hover:bg-stone-800/60'
            }`}
          >
            <Utensils className="w-4 h-4" />
            <span>Menu & Product Management</span>
          </button>

          <button
            onClick={() => setActiveTab('dashboard')}
            className={`px-4 py-2.5 rounded-xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
              activeTab === 'dashboard'
                ? 'bg-amber-500 text-stone-950 shadow-md shadow-orange-500/20'
                : 'text-stone-400 hover:text-stone-200 hover:bg-stone-800/60'
            }`}
          >
            <TrendingUp className="w-4 h-4" />
            <span>Overview & Metrics</span>
          </button>

          <button
            onClick={() => setActiveTab('orders')}
            className={`px-4 py-2.5 rounded-xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
              activeTab === 'orders'
                ? 'bg-amber-500 text-stone-950 shadow-md shadow-orange-500/20'
                : 'text-stone-400 hover:text-stone-200 hover:bg-stone-800/60'
            }`}
          >
            <ShoppingBag className="w-4 h-4" />
            <span>Orders Management</span>
            <span className="px-1.5 py-0.2 bg-stone-800 rounded-full text-[10px] font-mono font-bold text-amber-400">
              {orders.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('branches')}
            className={`px-4 py-2.5 rounded-xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
              activeTab === 'branches'
                ? 'bg-amber-500 text-stone-950 shadow-md shadow-orange-500/20'
                : 'text-stone-400 hover:text-stone-200 hover:bg-stone-800/60'
            }`}
          >
            <Store className="w-4 h-4" />
            <span>Branches & Outlets</span>
            <span className="px-1.5 py-0.2 bg-stone-800 rounded-full text-[10px] font-mono font-bold text-amber-400">
              {branches.length}
            </span>
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-6 space-y-6">
        {/* ────────────────────────────────────────────────────────── */}
        {/* TAB 1: MENU & PRODUCTS MANAGEMENT (CORE FOCUS)            */}
        {/* ────────────────────────────────────────────────────────── */}
        {activeTab === 'menu' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            {/* Sub-navigation & Quick Stats */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-stone-900 border border-stone-800 p-4 rounded-2xl">
              <div className="flex items-center gap-2 bg-stone-950 p-1 rounded-xl border border-stone-800">
                <button
                  onClick={() => setMenuSubTab('categories')}
                  className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                    menuSubTab === 'categories'
                      ? 'bg-stone-800 text-amber-400 shadow'
                      : 'text-stone-400 hover:text-stone-200'
                  }`}
                >
                  Categories ({categories.length})
                </button>
                <button
                  onClick={() => setMenuSubTab('products')}
                  className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                    menuSubTab === 'products'
                      ? 'bg-stone-800 text-amber-400 shadow'
                      : 'text-stone-400 hover:text-stone-200'
                  }`}
                >
                  Products & Variants ({products.length})
                </button>
                <button
                  onClick={() => setMenuSubTab('addons')}
                  className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                    menuSubTab === 'addons'
                      ? 'bg-stone-800 text-amber-400 shadow'
                      : 'text-stone-400 hover:text-stone-200'
                  }`}
                >
                  Add-ons ({addons.length})
                </button>
              </div>

              <div className="flex gap-2 w-full sm:w-auto">
                {menuSubTab === 'categories' && (
                  <button
                    onClick={() => openCategoryModal()}
                    className="px-4 py-2.5 bg-amber-500 hover:bg-amber-400 text-stone-950 font-black text-xs rounded-xl transition-all shadow-md shadow-orange-500/20 flex items-center gap-1.5"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Create Category</span>
                  </button>
                )}

                {menuSubTab === 'products' && (
                  <button
                    onClick={() => openProductModal()}
                    className="px-4 py-2.5 bg-amber-500 hover:bg-amber-400 text-stone-950 font-black text-xs rounded-xl transition-all shadow-md shadow-orange-500/20 flex items-center gap-1.5"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Create Product</span>
                  </button>
                )}

                {menuSubTab === 'addons' && (
                  <button
                    onClick={() => setShowAddonModal(true)}
                    className="px-4 py-2.5 bg-amber-500 hover:bg-amber-400 text-stone-950 font-black text-xs rounded-xl transition-all shadow-md shadow-orange-500/20 flex items-center gap-1.5"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Create Add-on</span>
                  </button>
                )}
              </div>
            </div>

            {/* ── Subtab A: Categories List ── */}
            {menuSubTab === 'categories' && (
              <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 space-y-4 shadow-xl">
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="text-lg font-black text-stone-100">Live Menu Categories</h3>
                    <p className="text-xs text-stone-400">
                      Categories manage how menu sections appear in both the Mobile Customer App & Online Store
                    </p>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs border-collapse">
                    <thead>
                      <tr className="border-b border-stone-800 text-stone-400 font-bold uppercase text-[10px] tracking-wider">
                        <th className="py-3 px-4">Image</th>
                        <th className="py-3 px-4">Category Name</th>
                        <th className="py-3 px-4">Description</th>
                        <th className="py-3 px-4 text-center">Sort Order</th>
                        <th className="py-3 px-4 text-center">Products</th>
                        <th className="py-3 px-4 text-center">Status</th>
                        <th className="py-3 px-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-stone-800/60 font-medium">
                      {categories.map((cat) => {
                        const linkedProductsCount = (cat.products || []).length;
                        return (
                          <tr key={cat.id} className="hover:bg-stone-800/40 transition-colors">
                            <td className="py-3 px-4">
                              <div className="w-12 h-12 rounded-xl bg-stone-950 border border-stone-800 overflow-hidden shrink-0">
                                {cat.image ? (
                                  <img src={cat.image} alt={cat.name} className="w-full h-full object-cover" />
                                ) : (
                                  <div className="w-full h-full flex items-center justify-center text-xl">🍕</div>
                                )}
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              <span className="font-extrabold text-stone-100 text-sm">{cat.name}</span>
                              <span className="block font-mono text-[10px] text-stone-500">{cat.id}</span>
                            </td>
                            <td className="py-3 px-4 text-stone-400 max-w-xs truncate">
                              {cat.description || '—'}
                            </td>
                            <td className="py-3 px-4 text-center font-mono font-bold text-amber-400">
                              {cat.sortOrder}
                            </td>
                            <td className="py-3 px-4 text-center">
                              <span className="px-2.5 py-1 bg-stone-800 text-stone-300 rounded-full font-bold text-[10px]">
                                {linkedProductsCount} items
                              </span>
                            </td>
                            <td className="py-3 px-4 text-center">
                              <button
                                onClick={() => handleToggleCategoryActive(cat)}
                                className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border transition-all ${
                                  cat.isActive
                                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/20'
                                    : 'bg-stone-800 text-stone-500 border-stone-700 hover:bg-stone-700'
                                }`}
                              >
                                {cat.isActive ? 'Active' : 'Hidden'}
                              </button>
                            </td>
                            <td className="py-3 px-4 text-right">
                              <div className="flex items-center justify-end gap-2">
                                <button
                                  onClick={() => openCategoryModal(cat)}
                                  className="p-1.5 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-lg transition-colors"
                                  title="Edit Category"
                                >
                                  <Edit2 className="w-3.5 h-3.5" />
                                </button>
                                <button
                                  onClick={() => handleDeleteCategory(cat)}
                                  className="p-1.5 bg-stone-800 hover:bg-red-500/20 text-stone-400 hover:text-red-400 rounded-lg transition-colors"
                                  title="Delete Category"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                      {categories.length === 0 && (
                        <tr>
                          <td colSpan={7} className="py-8 text-center text-stone-500">
                            No categories found. Click "Create Category" to get started.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* ── Subtab B: Products List & Filter ── */}
            {menuSubTab === 'products' && (
              <div className="space-y-4">
                {/* Search & Category Filter Bar */}
                <div className="flex flex-col sm:flex-row gap-3">
                  <div className="relative flex-1">
                    <Search className="w-4 h-4 text-stone-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={productSearch}
                      onChange={(e) => setProductSearch(e.target.value)}
                      placeholder="Search menu products..."
                      className="w-full bg-stone-900 border border-stone-800 rounded-xl pl-10 pr-4 py-2.5 text-xs text-stone-100 placeholder-stone-500 focus:outline-none focus:border-amber-500"
                    />
                  </div>

                  <select
                    value={selectedCategoryFilter}
                    onChange={(e) => setSelectedCategoryFilter(e.target.value)}
                    className="bg-stone-900 border border-stone-800 rounded-xl px-4 py-2.5 text-xs text-stone-200 font-bold outline-none focus:border-amber-500"
                  >
                    <option value="ALL">All Categories ({products.length})</option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Products Table */}
                <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 shadow-xl space-y-4">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs border-collapse">
                      <thead>
                        <tr className="border-b border-stone-800 text-stone-400 font-bold uppercase text-[10px] tracking-wider">
                          <th className="py-3 px-4">Image</th>
                          <th className="py-3 px-4">Product Details</th>
                          <th className="py-3 px-4">Category</th>
                          <th className="py-3 px-4">Base Price</th>
                          <th className="py-3 px-4">Variants / Sizes</th>
                          <th className="py-3 px-4">Add-ons</th>
                          <th className="py-3 px-4 text-center">Availability</th>
                          <th className="py-3 px-4 text-right">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-stone-800/60 font-medium">
                        {filteredProducts.map((prod) => {
                          const variantsList = prod.variants || [];
                          const addonsList = prod.addons || [];

                          return (
                            <tr key={prod.id} className="hover:bg-stone-800/40 transition-colors">
                              <td className="py-3 px-4">
                                <div className="w-12 h-12 rounded-xl bg-stone-950 border border-stone-800 overflow-hidden shrink-0">
                                  {prod.image ? (
                                    <img src={prod.image} alt={prod.name} className="w-full h-full object-cover" />
                                  ) : (
                                    <div className="w-full h-full flex items-center justify-center text-xl">🍔</div>
                                  )}
                                </div>
                              </td>
                              <td className="py-3 px-4">
                                <span className="font-extrabold text-stone-100 text-sm block">{prod.name}</span>
                                <span className="text-[11px] text-stone-400 line-clamp-1 max-w-xs">
                                  {prod.description || 'No description'}
                                </span>
                              </td>
                              <td className="py-3 px-4">
                                <span className="px-2.5 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 rounded-lg text-[10px] font-bold">
                                  {prod.category?.name || 'Uncategorized'}
                                </span>
                              </td>
                              <td className="py-3 px-4 font-mono font-black text-stone-100">
                                PKR {Number(prod.basePrice).toFixed(0)}
                              </td>
                              <td className="py-3 px-4">
                                {variantsList.length > 0 ? (
                                  <div className="space-y-0.5">
                                    {variantsList.map((v, idx) => (
                                      <span key={idx} className="block text-[10px] text-stone-300">
                                        • {v.name} (+PKR {Number(v.price).toFixed(0)})
                                      </span>
                                    ))}
                                  </div>
                                ) : (
                                  <span className="text-stone-500 text-[10px]">None (Base Only)</span>
                                )}
                              </td>
                              <td className="py-3 px-4">
                                {addonsList.length > 0 ? (
                                  <span className="px-2 py-0.5 bg-stone-800 text-stone-300 rounded text-[10px] font-bold">
                                    {addonsList.length} linked
                                  </span>
                                ) : (
                                  <span className="text-stone-500 text-[10px]">None</span>
                                )}
                              </td>
                              <td className="py-3 px-4 text-center">
                                <button
                                  onClick={() => handleToggleProductActive(prod)}
                                  className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border transition-all ${
                                    prod.isActive
                                      ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/20'
                                      : 'bg-red-500/10 text-red-400 border-red-500/30 hover:bg-red-500/20'
                                  }`}
                                >
                                  {prod.isActive ? 'Available' : 'Sold Out'}
                                </button>
                              </td>
                              <td className="py-3 px-4 text-right">
                                <div className="flex items-center justify-end gap-2">
                                  <button
                                    onClick={() => openProductModal(prod)}
                                    className="p-1.5 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-lg transition-colors"
                                    title="Edit Product"
                                  >
                                    <Edit2 className="w-3.5 h-3.5" />
                                  </button>
                                  <button
                                    onClick={() => handleDeleteProduct(prod)}
                                    className="p-1.5 bg-stone-800 hover:bg-red-500/20 text-stone-400 hover:text-red-400 rounded-lg transition-colors"
                                    title="Delete Product"
                                  >
                                    <Trash2 className="w-3.5 h-3.5" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                        {filteredProducts.length === 0 && (
                          <tr>
                            <td colSpan={8} className="py-8 text-center text-stone-500">
                              No products found matching your filters.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* ── Subtab C: Add-ons List ── */}
            {menuSubTab === 'addons' && (
              <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 space-y-4 shadow-xl">
                <div>
                  <h3 className="text-lg font-black text-stone-100">Menu Add-ons & Extras</h3>
                  <p className="text-xs text-stone-400">
                    Add-ons can be attached to products to allow customer customizations (e.g. Extra Cheese, Garlic Dip, Fries).
                  </p>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                  {addons.map((a) => (
                    <div
                      key={a.id}
                      className="bg-stone-950 border border-stone-800 p-4 rounded-2xl flex items-center justify-between"
                    >
                      <div>
                        <h4 className="font-extrabold text-stone-100 text-sm">{a.name}</h4>
                        <span className="font-mono text-xs font-bold text-amber-400">
                          +PKR {Number(a.price).toFixed(0)}
                        </span>
                      </div>
                      <button
                        onClick={() => handleDeleteAddon(a)}
                        className="p-2 text-stone-500 hover:text-red-400 hover:bg-stone-900 rounded-xl transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                  {addons.length === 0 && (
                    <div className="col-span-full py-8 text-center text-stone-500">
                      No add-ons created yet. Click "Create Add-on" above.
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        )}

        {/* ────────────────────────────────────────────────────────── */}
        {/* TAB 2: OVERVIEW & DASHBOARD METRICS                        */}
        {/* ────────────────────────────────────────────────────────── */}
        {activeTab === 'dashboard' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="bg-stone-900 border border-stone-800 p-5 rounded-3xl space-y-1">
                <span className="text-[10px] text-stone-400 font-black uppercase tracking-wider">Gross Revenue</span>
                <p className="text-2xl font-black text-amber-400">
                  PKR {Number(overview?.totalRevenue || 0).toLocaleString()}
                </p>
              </div>
              <div className="bg-stone-900 border border-stone-800 p-5 rounded-3xl space-y-1">
                <span className="text-[10px] text-stone-400 font-black uppercase tracking-wider">Total Orders</span>
                <p className="text-2xl font-black text-stone-100">{overview?.totalOrders || orders.length}</p>
              </div>
              <div className="bg-stone-900 border border-stone-800 p-5 rounded-3xl space-y-1">
                <span className="text-[10px] text-stone-400 font-black uppercase tracking-wider">Menu Categories</span>
                <p className="text-2xl font-black text-orange-400">{categories.length}</p>
              </div>
              <div className="bg-stone-900 border border-stone-800 p-5 rounded-3xl space-y-1">
                <span className="text-[10px] text-stone-400 font-black uppercase tracking-wider">Active Products</span>
                <p className="text-2xl font-black text-emerald-400">
                  {products.filter((p) => p.isActive).length} / {products.length}
                </p>
              </div>
            </div>

            {/* Quick Action Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div
                onClick={() => {
                  setActiveTab('menu');
                  setMenuSubTab('categories');
                  openCategoryModal();
                }}
                className="bg-stone-900 border border-stone-800 hover:border-amber-500/50 p-5 rounded-2xl cursor-pointer transition-all space-y-2 group"
              >
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center font-bold">
                  <Plus className="w-5 h-5" />
                </div>
                <h4 className="font-bold text-sm text-stone-100 group-hover:text-amber-400">Add New Category</h4>
                <p className="text-xs text-stone-400">
                  Define a new category to expand your menu in the mobile app and online store.
                </p>
              </div>

              <div
                onClick={() => {
                  setActiveTab('menu');
                  setMenuSubTab('products');
                  openProductModal();
                }}
                className="bg-stone-900 border border-stone-800 hover:border-amber-500/50 p-5 rounded-2xl cursor-pointer transition-all space-y-2 group"
              >
                <div className="w-10 h-10 rounded-xl bg-orange-500/10 text-orange-400 flex items-center justify-center font-bold">
                  <Utensils className="w-5 h-5" />
                </div>
                <h4 className="font-bold text-sm text-stone-100 group-hover:text-orange-400">Add Menu Item</h4>
                <p className="text-xs text-stone-400">
                  Create a new burger, pizza, beverage or dessert with custom price variants.
                </p>
              </div>

              <div
                onClick={() => setActiveTab('orders')}
                className="bg-stone-900 border border-stone-800 hover:border-amber-500/50 p-5 rounded-2xl cursor-pointer transition-all space-y-2 group"
              >
                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center font-bold">
                  <ShoppingBag className="w-5 h-5" />
                </div>
                <h4 className="font-bold text-sm text-stone-100 group-hover:text-emerald-400">Live Order Dispatch</h4>
                <p className="text-xs text-stone-400">
                  Review and fulfill incoming orders from Mobile Apps, Web, and POS terminals.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* ────────────────────────────────────────────────────────── */}
        {/* TAB 3: ORDERS MANAGEMENT                                   */}
        {/* ────────────────────────────────────────────────────────── */}
        {activeTab === 'orders' && (
          <div className="space-y-4 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
              <div>
                <h3 className="text-lg font-black text-stone-100">Live Orders Dispatch</h3>
                <p className="text-xs text-stone-400">
                  Manage incoming customer orders across all sales channels
                </p>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-xs text-stone-400 font-bold">Source:</span>
                <select
                  value={orderSourceFilter}
                  onChange={(e) => setOrderSourceFilter(e.target.value)}
                  className="bg-stone-900 border border-stone-800 text-stone-200 text-xs rounded-xl px-3 py-2 outline-none font-bold"
                >
                  <option value="ALL">All Channels</option>
                  <option value="MOBILE_APP">Mobile App</option>
                  <option value="WEBSITE">Website</option>
                  <option value="POS">POS Terminal</option>
                  <option value="PHONE">Phone</option>
                </select>
              </div>
            </div>

            <div className="bg-stone-900 border border-stone-800 rounded-3xl p-6 shadow-xl space-y-4">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-stone-800 text-stone-400 font-bold uppercase text-[10px] tracking-wider">
                      <th className="py-3 px-4">Order #</th>
                      <th className="py-3 px-4">Channel</th>
                      <th className="py-3 px-4">Customer</th>
                      <th className="py-3 px-4">Branch</th>
                      <th className="py-3 px-4">Total</th>
                      <th className="py-3 px-4">Payment</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4">Rider</th>
                      <th className="py-3 px-4">Change Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-stone-800/60 font-medium">
                    {filteredOrders.map((ord) => (
                      <tr key={ord.id} className="hover:bg-stone-800/40 transition-colors">
                        <td className="py-3 px-4 font-mono font-bold text-amber-400">{ord.orderNumber}</td>
                        <td className="py-3 px-4">
                          <span className="px-2 py-0.5 rounded text-[10px] font-black uppercase tracking-wider bg-stone-800 text-stone-300">
                            {ord.source || 'MOBILE_APP'}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <span className="block font-bold text-stone-200">
                            {ord.customer?.user?.name || 'Walk-in Customer'}
                          </span>
                          <span className="text-[10px] text-stone-500 font-mono">
                            {ord.customer?.user?.phone || '—'}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-stone-400">{ord.branch?.name || 'Main Branch'}</td>
                        <td className="py-3 px-4 font-mono font-black text-stone-100">
                          PKR {Number(ord.total).toFixed(2)}
                        </td>
                        <td className="py-3 px-4 text-[11px] text-stone-300">
                          {ord.paymentMethod?.replace('_', ' ')}
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <span className="px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider bg-orange-500/20 text-orange-400 border border-orange-500/30">
                              {ord.status}
                            </span>
                            {ord.status === 'PENDING' && (
                              <button
                                onClick={() => handleConfirmOrder(ord.id)}
                                disabled={confirmingOrderId === ord.id}
                                className="px-2.5 py-1 bg-emerald-500 hover:bg-emerald-600 text-stone-950 text-[10px] font-black rounded-lg disabled:opacity-50 transition-colors"
                              >
                                {confirmingOrderId === ord.id ? '...' : '✓ Confirm'}
                              </button>
                            )}
                          </div>
                        </td>
                        <td className="py-3 px-4 min-w-[180px]">
                          {ord.delivery?.rider ? (
                            <div>
                              <span className="block font-bold text-emerald-400">{ord.delivery.rider.user?.name}</span>
                              <span className="text-[10px] text-stone-500 font-mono">{ord.delivery.rider.user?.phone}</span>
                              <span className="block text-[10px] text-stone-500 uppercase">{ord.delivery.status}</span>
                            </div>
                          ) : ord.type === 'DELIVERY' && ord.status === 'READY' ? (
                            <div className="flex items-center gap-1.5">
                              <select
                                value={selectedRiderByOrder[ord.id] || ''}
                                onChange={(e) => setSelectedRiderByOrder((prev) => ({ ...prev, [ord.id]: e.target.value }))}
                                className="bg-stone-800 border border-stone-700 text-stone-200 text-[11px] rounded-lg px-2 py-1 outline-none font-bold max-w-[110px]"
                              >
                                <option value="">Select...</option>
                                {riders
                                  .filter((r) => r.status === 'ONLINE' && (!ord.branchId || r.branchId === ord.branchId))
                                  .map((r) => (
                                    <option key={r.id} value={r.id}>{r.user?.name}</option>
                                  ))}
                              </select>
                              <button
                                onClick={() => handleAssignRider(ord.id)}
                                disabled={assigningOrderId === ord.id}
                                className="px-2 py-1 bg-amber-500 hover:bg-amber-600 text-stone-950 text-[10px] font-black rounded-lg disabled:opacity-50"
                              >
                                {assigningOrderId === ord.id ? '...' : 'Assign'}
                              </button>
                            </div>
                          ) : (
                            <span className="text-stone-600 text-[11px]">
                              {ord.type === 'PICKUP' ? 'Pickup order' : '—'}
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-4">
                          {ord.delivery?.rider && !['DELIVERED', 'FAILED'].includes(ord.delivery.status) ? (
                            <div
                              className="px-2.5 py-1.5 rounded-lg bg-stone-800/60 border border-stone-700 text-stone-400 text-[10px] font-bold text-center leading-tight"
                              title="A rider owns this delivery now — status advances automatically as they accept, pick up, and deliver it."
                            >
                              🔒 Tracked via rider app
                            </div>
                          ) : ['DELIVERED', 'CANCELLED'].includes(ord.status) ? (
                            <div
                              className="px-2.5 py-1.5 rounded-lg bg-stone-800/60 border border-stone-700 text-stone-400 text-[10px] font-bold text-center leading-tight"
                              title="This order is complete — its final status can't be edited from here."
                            >
                              🔒 {ord.status}
                            </div>
                          ) : (
                            <select
                              value={ord.status}
                              onChange={(e) => handleUpdateOrderStatus(ord.id, e.target.value)}
                              className="bg-stone-800 border border-stone-700 text-stone-200 text-[11px] rounded-lg px-2.5 py-1 outline-none font-bold"
                            >
                              <option value="PENDING">PENDING</option>
                              <option value="CONFIRMED">CONFIRMED</option>
                              <option value="PREPARING">PREPARING</option>
                              <option value="READY">READY</option>
                              <option value="OUT_FOR_DELIVERY">OUT_FOR_DELIVERY</option>
                              <option value="DELIVERED">DELIVERED</option>
                              <option value="CANCELLED">CANCELLED</option>
                            </select>
                          )}
                        </td>
                      </tr>
                    ))}
                    {filteredOrders.length === 0 && (
                      <tr>
                        <td colSpan={9} className="py-8 text-center text-stone-500">
                          No orders found matching this filter.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ────────────────────────────────────────────────────────── */}
        {/* TAB 4: BRANCHES & OUTLETS OVERVIEW                         */}
        {/* ────────────────────────────────────────────────────────── */}
        {activeTab === 'branches' && (
          <div className="space-y-4 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
              <div>
                <h3 className="text-lg font-black text-stone-100">Outlets & Branch Performance</h3>
                <p className="text-xs text-stone-400">
                  Operating locations, delivery zones and live availability
                </p>
              </div>
              <button
                onClick={() => openBranchModal()}
                className="px-5 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-stone-950 font-black rounded-2xl text-xs flex items-center gap-2 shadow-lg shadow-orange-500/20 transition-all cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>Add Branch</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {branches.map((b) => (
                <div key={b.id} className="bg-stone-900 border border-stone-800 p-6 rounded-3xl space-y-4 flex flex-col justify-between">
                  <div className="space-y-4">
                    <div className="flex justify-between items-start">
                      <div>
                        <span className="font-mono text-[10px] font-bold text-amber-400 uppercase tracking-widest block">
                          {b.code}
                        </span>
                        <h4 className="text-base font-black text-stone-100">{b.name}</h4>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleToggleBranchOpen(b)}
                        className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border transition-all cursor-pointer ${
                          b.isOpen
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/20'
                            : 'bg-red-500/10 text-red-400 border-red-500/30 hover:bg-red-500/20'
                        }`}
                        title="Click to toggle open/closed status"
                      >
                        {b.isOpen ? 'Open Now' : 'Closed'}
                      </button>
                    </div>

                    <p className="text-xs text-stone-400 flex items-center gap-1.5">
                      <MapPin className="w-3.5 h-3.5 text-stone-500 shrink-0" />
                      <span>{b.address}</span>
                    </p>

                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-stone-800/80 text-xs">
                      <div>
                        <span className="text-[10px] text-stone-500 block font-bold">Delivery Radius</span>
                        <span className="font-bold text-stone-200">{Number(b.deliveryRadius)} km</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-stone-500 block font-bold">Direct Phone</span>
                        <span className="font-bold text-stone-200">{b.phone || '—'}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-3 border-t border-stone-800/80">
                    <button
                      type="button"
                      onClick={() => openBranchModal(b)}
                      className="flex-1 py-2 bg-stone-800 hover:bg-amber-500 hover:text-stone-950 text-stone-200 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer"
                      title="Edit Branch"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                      <span>Edit Branch</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteBranch(b)}
                      className="px-3.5 py-2 bg-stone-800 hover:bg-red-500/20 text-stone-400 hover:text-red-400 border border-transparent hover:border-red-500/30 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer"
                      title="Delete Branch"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
              {branches.length === 0 && (
                <div className="col-span-full py-12 text-center text-stone-500 bg-stone-900 border border-stone-800 rounded-3xl">
                  No branch outlets found. Click "Add Branch" above to register your first branch.
                </div>
              )}
            </div>
          </div>
        )}
      </main>

      {/* ────────────────────────────────────────────────────────── */}
      {/* MODAL: ADD / EDIT CATEGORY                                 */}
      {/* ────────────────────────────────────────────────────────── */}
      {showCategoryModal && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-3 sm:p-4">
          <div className="bg-stone-900 border border-stone-800 max-w-lg w-full rounded-3xl shadow-2xl flex flex-col max-h-[92vh] overflow-hidden animate-in zoom-in-95 duration-150">
            <div className="flex justify-between items-center px-6 py-4 border-b border-stone-800 shrink-0">
              <h3 className="text-lg font-black text-stone-100">
                {editingCategory ? `Edit Category: ${editingCategory.name}` : 'Create Menu Category'}
              </h3>
              <button
                onClick={() => setShowCategoryModal(false)}
                className="p-1.5 text-stone-500 hover:text-stone-300 rounded-xl hover:bg-stone-800 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form id="categoryForm" onSubmit={handleSaveCategory} className="p-6 overflow-y-auto space-y-4 text-xs flex-1">
              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Category Name *
                </label>
                <input
                  type="text"
                  value={categoryForm.name}
                  onChange={(e) => setCategoryForm({ ...categoryForm, name: e.target.value })}
                  placeholder="e.g. Gourmet Burgers, Artisan Pizzas"
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500 font-bold"
                  required
                />
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Description
                </label>
                <textarea
                  value={categoryForm.description}
                  onChange={(e) => setCategoryForm({ ...categoryForm, description: e.target.value })}
                  rows={2}
                  placeholder="Appetizing description for customers..."
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2 text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500"
                />
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Cover Photo / Image
                </label>
                {categoryForm.image ? (
                  <div className="relative rounded-2xl overflow-hidden border border-stone-800 bg-stone-950 group">
                    <img src={categoryForm.image} alt="Preview" className="w-full h-36 object-cover" />
                    <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-3">
                      <label className="cursor-pointer px-3.5 py-1.5 bg-amber-500 hover:bg-amber-400 text-stone-950 font-black text-xs rounded-xl shadow transition-colors">
                        Change Photo
                        <input
                          type="file"
                          accept="image/*"
                          className="hidden"
                          onChange={(e) => {
                            const f = e.target.files?.[0];
                            if (f) handleFileUpload(f, (url) => setCategoryForm({ ...categoryForm, image: url }));
                          }}
                        />
                      </label>
                      <button
                        type="button"
                        onClick={() => setCategoryForm({ ...categoryForm, image: '' })}
                        className="px-3.5 py-1.5 bg-red-500 hover:bg-red-400 text-white font-bold text-xs rounded-xl shadow transition-colors"
                      >
                        Remove
                      </button>
                    </div>
                  </div>
                ) : (
                  <label className="border-2 border-dashed border-stone-800 hover:border-amber-500/60 rounded-2xl p-6 flex flex-col items-center justify-center gap-2 cursor-pointer bg-stone-950/60 hover:bg-stone-950 transition-colors">
                    <div className="w-10 h-10 rounded-full bg-amber-500/10 text-amber-400 flex items-center justify-center">
                      <Upload className="w-5 h-5" />
                    </div>
                    <p className="text-xs font-bold text-stone-200">
                      Click to upload category image from device
                    </p>
                    <p className="text-[10px] text-stone-500">
                      PNG, JPG, JPEG, WEBP up to 10MB
                    </p>
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => {
                        const f = e.target.files?.[0];
                        if (f) handleFileUpload(f, (url) => setCategoryForm({ ...categoryForm, image: url }));
                      }}
                    />
                  </label>
                )}
                {uploadingImage && (
                  <p className="text-[10px] text-amber-400 flex items-center gap-1.5 mt-1.5 animate-pulse">
                    <RefreshCw className="w-3 h-3 animate-spin" /> Uploading image...
                  </p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Sort Order
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={categoryForm.sortOrder}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (val === '') {
                        setCategoryForm({ ...categoryForm, sortOrder: '' });
                      } else {
                        const parsed = parseInt(val, 10);
                        setCategoryForm({
                          ...categoryForm,
                          sortOrder: isNaN(parsed) ? '' : Math.max(0, parsed),
                        });
                      }
                    }}
                    placeholder="1"
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2 text-stone-100 focus:outline-none focus:border-amber-500 font-mono"
                  />
                </div>

                <div className="flex items-center gap-3 pt-5">
                  <input
                    type="checkbox"
                    id="catIsActive"
                    checked={categoryForm.isActive}
                    onChange={(e) => setCategoryForm({ ...categoryForm, isActive: e.target.checked })}
                    className="w-4 h-4 accent-amber-500 rounded"
                  />
                  <label htmlFor="catIsActive" className="text-stone-300 font-bold cursor-pointer">
                    Visible in App
                  </label>
                </div>
              </div>
            </form>

            <div className="px-6 py-4 border-t border-stone-800 bg-stone-900/90 flex justify-end gap-2 shrink-0">
              <button
                type="button"
                onClick={() => setShowCategoryModal(false)}
                className="px-4 py-2.5 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-xl font-bold transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                form="categoryForm"
                className="px-6 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-stone-950 rounded-xl font-black shadow-lg shadow-orange-500/20 transition-all cursor-pointer"
              >
                {editingCategory ? 'Save Changes' : 'Create Category'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ────────────────────────────────────────────────────────── */}
      {/* MODAL: ADD / EDIT PRODUCT                                  */}
      {/* ────────────────────────────────────────────────────────── */}
      {showProductModal && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-3 sm:p-4">
          <div className="bg-stone-900 border border-stone-800 max-w-2xl w-full rounded-3xl shadow-2xl flex flex-col max-h-[92vh] overflow-hidden animate-in zoom-in-95 duration-150">
            <div className="flex justify-between items-center px-6 py-4 border-b border-stone-800 shrink-0">
              <h3 className="text-lg font-black text-stone-100">
                {editingProduct ? `Edit Item: ${editingProduct.name}` : 'Add New Menu Item'}
              </h3>
              <button
                onClick={() => setShowProductModal(false)}
                className="p-1.5 text-stone-500 hover:text-stone-300 rounded-xl hover:bg-stone-800 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form id="productForm" onSubmit={handleSaveProduct} className="p-6 overflow-y-auto space-y-4 text-xs flex-1">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Category *
                  </label>
                  <select
                    value={productForm.categoryId}
                    onChange={(e) => setProductForm({ ...productForm, categoryId: e.target.value })}
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-3.5 py-2.5 text-stone-100 font-bold focus:outline-none focus:border-amber-500"
                    required
                  >
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Base Price (PKR) *
                  </label>
                  <input
                    type="number"
                    min="0"
                    step="1"
                    value={productForm.basePrice}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (val === '') {
                        setProductForm({ ...productForm, basePrice: '' });
                      } else {
                        const parsed = parseFloat(val);
                        setProductForm({
                          ...productForm,
                          basePrice: isNaN(parsed) ? '' : Math.max(0, parsed),
                        });
                      }
                    }}
                    placeholder="450"
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 font-mono font-bold focus:outline-none focus:border-amber-500"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Item Name *
                </label>
                <input
                  type="text"
                  value={productForm.name}
                  onChange={(e) => setProductForm({ ...productForm, name: e.target.value })}
                  placeholder="e.g. Smoky Beef Smash Burger, Loaded Pepperoni"
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 font-bold placeholder-stone-600 focus:outline-none focus:border-amber-500"
                  required
                />
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Description & Ingredients
                </label>
                <textarea
                  value={productForm.description}
                  onChange={(e) => setProductForm({ ...productForm, description: e.target.value })}
                  rows={2}
                  placeholder="Crispy fried chicken breast filet topped with signature spicy mayo..."
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2 text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500"
                />
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Product Photo / Image
                </label>
                {productForm.image ? (
                  <div className="relative rounded-2xl overflow-hidden border border-stone-800 bg-stone-950 group">
                    <img src={productForm.image} alt="Preview" className="w-full h-40 object-cover" />
                    <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-3">
                      <label className="cursor-pointer px-3.5 py-1.5 bg-amber-500 hover:bg-amber-400 text-stone-950 font-black text-xs rounded-xl shadow transition-colors">
                        Change Photo
                        <input
                          type="file"
                          accept="image/*"
                          className="hidden"
                          onChange={(e) => {
                            const f = e.target.files?.[0];
                            if (f) handleFileUpload(f, (url) => setProductForm({ ...productForm, image: url }));
                          }}
                        />
                      </label>
                      <button
                        type="button"
                        onClick={() => setProductForm({ ...productForm, image: '' })}
                        className="px-3.5 py-1.5 bg-red-500 hover:bg-red-400 text-white font-bold text-xs rounded-xl shadow transition-colors"
                      >
                        Remove
                      </button>
                    </div>
                  </div>
                ) : (
                  <label className="border-2 border-dashed border-stone-800 hover:border-amber-500/60 rounded-2xl p-6 flex flex-col items-center justify-center gap-2 cursor-pointer bg-stone-950/60 hover:bg-stone-950 transition-colors">
                    <div className="w-10 h-10 rounded-full bg-amber-500/10 text-amber-400 flex items-center justify-center">
                      <Upload className="w-5 h-5" />
                    </div>
                    <p className="text-xs font-bold text-stone-200">
                      Click to upload product image from device
                    </p>
                    <p className="text-[10px] text-stone-500">
                      PNG, JPG, JPEG, WEBP up to 10MB
                    </p>
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => {
                        const f = e.target.files?.[0];
                        if (f) handleFileUpload(f, (url) => setProductForm({ ...productForm, image: url }));
                      }}
                    />
                  </label>
                )}
                {uploadingImage && (
                  <p className="text-[10px] text-amber-400 flex items-center gap-1.5 mt-1.5 animate-pulse">
                    <RefreshCw className="w-3 h-3 animate-spin" /> Uploading image...
                  </p>
                )}
              </div>

              {/* Dynamic Variants Builder */}
              <div className="p-4 bg-stone-950 border border-stone-800 rounded-2xl space-y-3">
                <div className="flex justify-between items-center">
                  <label className="text-stone-300 font-bold uppercase tracking-wider text-[11px]">
                    Size / Portion Variants (Optional)
                  </label>
                  <button
                    type="button"
                    onClick={() =>
                      setProductForm({
                        ...productForm,
                        variants: [
                          ...productForm.variants,
                          { name: 'Large', price: 200, isDefault: false },
                        ],
                      })
                    }
                    className="text-[11px] text-amber-400 hover:underline font-bold flex items-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add Size Variant</span>
                  </button>
                </div>

                {productForm.variants.map((v, idx) => (
                  <div key={idx} className="flex gap-2 items-center">
                    <input
                      type="text"
                      placeholder="Variant Name (e.g. Medium, Large)"
                      value={v.name}
                      onChange={(e) => {
                        const newVars = [...productForm.variants];
                        newVars[idx].name = e.target.value;
                        setProductForm({ ...productForm, variants: newVars });
                      }}
                      className="flex-1 bg-stone-900 border border-stone-800 rounded-lg px-3 py-1.5 text-stone-200"
                    />
                    <div className="flex items-center gap-1">
                      <span className="text-stone-500 text-[10px]">PKR +</span>
                      <input
                        type="number"
                        placeholder="Offset"
                        value={v.price}
                        onChange={(e) => {
                          const val = e.target.value;
                          const newVars = [...productForm.variants];
                          if (val === '') {
                            (newVars[idx] as any).price = '';
                          } else {
                            const parsed = parseFloat(val);
                            newVars[idx].price = isNaN(parsed) ? ('' as any) : parsed;
                          }
                          setProductForm({ ...productForm, variants: newVars });
                        }}
                        className="w-20 bg-stone-900 border border-stone-800 rounded-lg px-2 py-1.5 text-stone-200 font-mono"
                      />
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        const newVars = productForm.variants.filter((_, i) => i !== idx);
                        setProductForm({ ...productForm, variants: newVars });
                      }}
                      className="p-1.5 text-stone-500 hover:text-red-400"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
                {productForm.variants.length === 0 && (
                  <p className="text-[11px] text-stone-600 italic">No variants added. Base price will apply.</p>
                )}
              </div>

              {/* Add-ons Selection */}
              {addons.length > 0 && (
                <div className="p-4 bg-stone-950 border border-stone-800 rounded-2xl space-y-2">
                  <label className="text-stone-300 font-bold uppercase tracking-wider text-[11px] block">
                    Available Add-ons for this Item
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    {addons.map((add) => {
                      const isChecked = productForm.addonIds.includes(add.id);
                      return (
                        <label
                          key={add.id}
                          className={`p-2.5 rounded-xl border flex items-center gap-2 cursor-pointer transition-colors ${
                            isChecked
                              ? 'bg-amber-500/10 border-amber-500/40 text-amber-300'
                              : 'bg-stone-900/60 border-stone-800 text-stone-400 hover:border-stone-700'
                          }`}
                        >
                          <input
                            type="checkbox"
                            checked={isChecked}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setProductForm({
                                  ...productForm,
                                  addonIds: [...productForm.addonIds, add.id],
                                });
                              } else {
                                setProductForm({
                                  ...productForm,
                                  addonIds: productForm.addonIds.filter((id) => id !== add.id),
                                });
                              }
                            }}
                            className="w-4 h-4 accent-amber-500 rounded"
                          />
                          <span className="font-bold text-xs">{add.name}</span>
                          <span className="ml-auto text-[10px] font-mono text-stone-400">
                            +PKR {Number(add.price)}
                          </span>
                        </label>
                      );
                    })}
                  </div>
                </div>
              )}

              <div className="flex items-center gap-3 pt-2">
                <input
                  type="checkbox"
                  id="prodIsActive"
                  checked={productForm.isActive}
                  onChange={(e) => setProductForm({ ...productForm, isActive: e.target.checked })}
                  className="w-4 h-4 accent-amber-500 rounded"
                />
                <label htmlFor="prodIsActive" className="text-stone-300 font-bold cursor-pointer">
                  Available for Ordering (In-Stock)
                </label>
              </div>
            </form>

            <div className="px-6 py-4 border-t border-stone-800 bg-stone-900/90 flex justify-end gap-2 shrink-0">
              <button
                type="button"
                onClick={() => setShowProductModal(false)}
                className="px-4 py-2.5 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-xl font-bold transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                form="productForm"
                className="px-6 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-stone-950 rounded-xl font-black shadow-lg shadow-orange-500/20 transition-all cursor-pointer"
              >
                {editingProduct ? 'Save Product' : 'Add to Menu'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ────────────────────────────────────────────────────────── */}
      {/* MODAL: ADD BRANCH                                          */}
      {/* ────────────────────────────────────────────────────────── */}
      {showBranchModal && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-3 sm:p-4">
          <div className="bg-stone-900 border border-stone-800 max-w-xl w-full rounded-3xl shadow-2xl flex flex-col max-h-[92vh] overflow-hidden animate-in zoom-in-95 duration-150">
            <div className="flex justify-between items-center px-6 py-4 border-b border-stone-800 shrink-0">
              <h3 className="text-lg font-black text-stone-100">
                {editingBranch ? `Edit Branch: ${editingBranch.name}` : 'Create New Branch Outlet'}
              </h3>
              <button
                onClick={() => {
                  setShowBranchModal(false);
                  setEditingBranch(null);
                }}
                className="p-1.5 text-stone-500 hover:text-stone-300 rounded-xl hover:bg-stone-800 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form id="branchForm" onSubmit={handleSaveBranch} className="p-6 overflow-y-auto space-y-4 text-xs flex-1">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Branch Name *
                  </label>
                  <input
                    type="text"
                    value={branchForm.name}
                    onChange={(e) => setBranchForm({ ...branchForm, name: e.target.value })}
                    placeholder="e.g. HungerPoint F-10 Markaz"
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500 font-bold"
                    required
                  />
                </div>

                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Branch Code *
                  </label>
                  <input
                    type="text"
                    value={branchForm.code}
                    onChange={(e) => setBranchForm({ ...branchForm, code: e.target.value })}
                    placeholder="e.g. HP-F10"
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500 font-mono font-bold"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Full Address *
                </label>
                <input
                  type="text"
                  value={branchForm.address}
                  onChange={(e) => setBranchForm({ ...branchForm, address: e.target.value })}
                  placeholder="e.g. Shop 15, Street 18, F-10 Markaz, Islamabad"
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 placeholder-stone-600 focus:outline-none focus:border-amber-500"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    City *
                  </label>
                  <input
                    type="text"
                    value={branchForm.city}
                    onChange={(e) => setBranchForm({ ...branchForm, city: e.target.value })}
                    placeholder="e.g. Islamabad"
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 focus:outline-none focus:border-amber-500"
                    required
                  />
                </div>

                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Direct Contact Phone
                  </label>
                  <input
                    type="text"
                    value={branchForm.phone}
                    onChange={(e) => setBranchForm({ ...branchForm, phone: e.target.value })}
                    placeholder="+923001234567"
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 font-mono focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Latitude
                  </label>
                  <input
                    type="number"
                    step="0.0001"
                    value={branchForm.latitude}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (val === '') {
                        setBranchForm({ ...branchForm, latitude: '' });
                      } else {
                        const parsed = parseFloat(val);
                        setBranchForm({ ...branchForm, latitude: isNaN(parsed) ? '' : parsed });
                      }
                    }}
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-3 py-2 text-stone-100 font-mono focus:outline-none focus:border-amber-500"
                    required
                  />
                </div>

                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Longitude
                  </label>
                  <input
                    type="number"
                    step="0.0001"
                    value={branchForm.longitude}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (val === '') {
                        setBranchForm({ ...branchForm, longitude: '' });
                      } else {
                        const parsed = parseFloat(val);
                        setBranchForm({ ...branchForm, longitude: isNaN(parsed) ? '' : parsed });
                      }
                    }}
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-3 py-2 text-stone-100 font-mono focus:outline-none focus:border-amber-500"
                    required
                  />
                </div>

                <div>
                  <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                    Radius (KM)
                  </label>
                  <input
                    type="number"
                    min="0.5"
                    step="0.5"
                    value={branchForm.deliveryRadius}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (val === '') {
                        setBranchForm({ ...branchForm, deliveryRadius: '' });
                      } else {
                        const parsed = parseFloat(val);
                        setBranchForm({ ...branchForm, deliveryRadius: isNaN(parsed) ? '' : Math.max(0.5, parsed) });
                      }
                    }}
                    className="w-full bg-stone-950 border border-stone-800 rounded-xl px-3 py-2 text-stone-100 font-mono focus:outline-none focus:border-amber-500"
                    required
                  />
                </div>
              </div>

              <div className="flex items-center gap-6 pt-2">
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="branchIsOpen"
                    checked={branchForm.isOpen}
                    onChange={(e) => setBranchForm({ ...branchForm, isOpen: e.target.checked })}
                    className="w-4 h-4 accent-amber-500 rounded"
                  />
                  <label htmlFor="branchIsOpen" className="text-stone-300 font-bold cursor-pointer">
                    Open for Orders Now
                  </label>
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="branchIsActive"
                    checked={branchForm.isActive}
                    onChange={(e) => setBranchForm({ ...branchForm, isActive: e.target.checked })}
                    className="w-4 h-4 accent-amber-500 rounded"
                  />
                  <label htmlFor="branchIsActive" className="text-stone-300 font-bold cursor-pointer">
                    Active in Customer App
                  </label>
                </div>
              </div>
            </form>

            <div className="px-6 py-4 border-t border-stone-800 bg-stone-900/90 flex justify-end gap-2 shrink-0">
              <button
                type="button"
                onClick={() => {
                  setShowBranchModal(false);
                  setEditingBranch(null);
                }}
                className="px-4 py-2.5 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-xl font-bold transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                form="branchForm"
                className="px-6 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-stone-950 rounded-xl font-black shadow-lg shadow-orange-500/20 transition-all cursor-pointer"
              >
                {editingBranch ? 'Save Branch Changes' : 'Create Branch Outlet'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ────────────────────────────────────────────────────────── */}
      {/* MODAL: ADD ADDON                                           */}
      {/* ────────────────────────────────────────────────────────── */}
      {showAddonModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-stone-900 border border-stone-800 max-w-sm w-full rounded-3xl p-6 shadow-2xl space-y-4 animate-in zoom-in-95 duration-150">
            <div className="flex justify-between items-center pb-2 border-b border-stone-800">
              <h3 className="text-base font-black text-stone-100">Create Add-on</h3>
              <button
                onClick={() => setShowAddonModal(false)}
                className="p-1 text-stone-500 hover:text-stone-300"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateAddon} className="space-y-4 text-xs">
              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Add-on Name *
                </label>
                <input
                  type="text"
                  value={addonForm.name}
                  onChange={(e) => setAddonForm({ ...addonForm, name: e.target.value })}
                  placeholder="e.g. Extra Cheddar Slice, Spicy Mayo Dip"
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 focus:outline-none focus:border-amber-500"
                  required
                />
              </div>

              <div>
                <label className="block text-stone-400 font-bold uppercase tracking-wider mb-1">
                  Price (PKR) *
                </label>
                <input
                  type="number"
                  min="0"
                  value={addonForm.price}
                  onChange={(e) => {
                    const val = e.target.value;
                    if (val === '') {
                      setAddonForm({ ...addonForm, price: '' });
                    } else {
                      const parsed = parseFloat(val);
                      setAddonForm({ ...addonForm, price: isNaN(parsed) ? '' : Math.max(0, parsed) });
                    }
                  }}
                  className="w-full bg-stone-950 border border-stone-800 rounded-xl px-4 py-2.5 text-stone-100 font-mono font-bold focus:outline-none focus:border-amber-500"
                  required
                />
              </div>

              <div className="flex justify-end gap-2 pt-2 border-t border-stone-800">
                <button
                  type="button"
                  onClick={() => setShowAddonModal(false)}
                  className="px-4 py-2 bg-stone-800 hover:bg-stone-700 text-stone-300 rounded-xl font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-amber-500 hover:bg-amber-400 text-stone-950 rounded-xl font-black"
                >
                  Save Add-on
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
