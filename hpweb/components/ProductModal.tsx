// ============================================================
// HungerPoint Web App — Product Detail & Addon Modal
// ============================================================

'use client';

import React, { useState } from 'react';
import { useCart } from '../context/CartContext';

export interface ProductDetail {
  id: string;
  name: string;
  description?: string;
  image?: string;
  basePrice: number;
  variants?: { id: string; name: string; price: number; isDefault?: boolean }[];
  addons?: { id: string; name: string; price: number }[];
}

export function ProductModal({
  product,
  onClose,
}: {
  product: ProductDetail | null;
  onClose: () => void;
}) {
  if (!product) return null;

  return <ProductModalContent product={product} onClose={onClose} />;
}

function ProductModalContent({
  product,
  onClose,
}: {
  product: ProductDetail;
  onClose: () => void;
}) {
  const { addItem } = useCart();

  const defaultVariant = product.variants?.find((v) => v.isDefault) || product.variants?.[0];
  const [selectedVariant, setSelectedVariant] = useState(defaultVariant || null);
  const [quantity, setQuantity] = useState(1);
  const [notes, setNotes] = useState('');

  const variantPrice = selectedVariant ? Number(selectedVariant.price) : 0;
  const unitPrice = Number(product.basePrice) + variantPrice;
  const totalPrice = unitPrice * quantity;

  const handleAddToCart = () => {
    addItem({
      productId: product.id,
      name: product.name,
      image: product.image,
      price: unitPrice,
      quantity,
      variantId: selectedVariant?.id,
      variantName: selectedVariant?.name,
      notes,
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
      <div className="w-full max-w-lg bg-stone-900 border border-stone-800 rounded-3xl overflow-hidden shadow-2xl text-stone-100 relative max-h-[90vh] flex flex-col">
        
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 z-10 text-white bg-black/60 hover:bg-black/80 w-8 h-8 rounded-full flex items-center justify-center text-sm"
        >
          ✕
        </button>

        {/* Product Image */}
        {product.image && (
          <div className="relative h-56 w-full bg-stone-800">
            <img src={product.image} alt={product.name} className="w-full h-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-t from-stone-900 via-transparent to-black/20" />
          </div>
        )}

        <div className="p-6 overflow-y-auto space-y-5 flex-1">
          <div>
            <h3 className="text-2xl font-black text-stone-100">{product.name}</h3>
            <p className="text-xs text-stone-400 mt-1 leading-relaxed">{product.description}</p>
          </div>

          {/* Variants Selection */}
          {product.variants && product.variants.length > 0 && (
            <div>
              <label className="text-xs font-extrabold text-amber-400 uppercase tracking-wider block mb-2">
                Choose Size / Option
              </label>
              <div className="grid grid-cols-2 gap-2">
                {product.variants.map((v) => (
                  <button
                    key={v.id}
                    type="button"
                    onClick={() => setSelectedVariant(v)}
                    className={`p-3 rounded-2xl text-xs font-bold border text-left flex justify-between items-center transition-all ${
                      selectedVariant?.id === v.id
                        ? 'border-amber-500 bg-amber-500/10 text-amber-400 shadow-md'
                        : 'border-stone-800 bg-stone-800/40 text-stone-400 hover:text-stone-200'
                    }`}
                  >
                    <span>{v.name}</span>
                    <span className="text-[11px] font-mono opacity-80">
                      {Number(v.price) > 0 ? `+PKR ${Number(v.price)}` : 'Standard'}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Special Instructions */}
          <div>
            <label className="text-xs font-extrabold text-stone-400 uppercase tracking-wider block mb-1.5">
              Special Instructions
            </label>
            <input
              type="text"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="e.g. No mayo, extra spicy, etc."
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500"
            />
          </div>
        </div>

        {/* Footer with Quantity & Add Button */}
        <div className="p-5 border-t border-stone-800 bg-stone-950 flex items-center justify-between gap-4">
          {/* Quantity selector */}
          <div className="flex items-center gap-3 bg-stone-800 px-3 py-2 rounded-2xl border border-stone-700/60">
            <button
              onClick={() => setQuantity(Math.max(1, quantity - 1))}
              className="text-stone-300 hover:text-white font-bold text-base w-6 text-center"
            >
              -
            </button>
            <span className="text-sm font-extrabold text-amber-400 w-5 text-center">{quantity}</span>
            <button
              onClick={() => setQuantity(quantity + 1)}
              className="text-stone-300 hover:text-white font-bold text-base w-6 text-center"
            >
              +
            </button>
          </div>

          {/* Add to Cart Button */}
          <button
            onClick={handleAddToCart}
            className="flex-1 py-3.5 bg-gradient-to-r from-amber-500 via-orange-600 to-red-600 hover:from-amber-600 hover:to-red-700 text-white font-extrabold text-xs rounded-2xl shadow-lg shadow-orange-500/30 transition-all transform active:scale-95 flex justify-between px-5"
          >
            <span>Add to Order</span>
            <span>PKR {totalPrice.toFixed(2)}</span>
          </button>
        </div>

      </div>
    </div>
  );
}
