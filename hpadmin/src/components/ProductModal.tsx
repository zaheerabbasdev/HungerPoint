// ============================================================
// HungerPoint Web App — Product detail modal (customer)
// ============================================================

import { useCart } from '../context/CartContext';
import { resolveImageUrl } from '../lib/api';
import type { MenuProduct } from '../lib/menu';
import { ItemCustomizer } from './ItemCustomizer';

export type ProductDetail = MenuProduct;

export function ProductModal({ product, onClose }: { product: ProductDetail | null; onClose: () => void }) {
  const { addItem } = useCart();
  if (!product) return null;

  return (
    <ItemCustomizer
      key={product.id}
      product={product}
      resolveImage={resolveImageUrl}
      onClose={onClose}
      onConfirm={(line) => {
        addItem(line);
        onClose();
      }}
    />
  );
}
