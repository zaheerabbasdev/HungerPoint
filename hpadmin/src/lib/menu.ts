// ============================================================
// HungerPoint Web App — Menu & order-line helpers
// ============================================================
// Mirrors hpcustomer/lib/services/order_payload.dart so the website and the
// mobile app send the same order lines.
//
// The server prices an order itself: product base price + the chosen size's
// offset + each add-on, per unit. Lines must therefore carry the real size
// (`variantId`) and add-on ids. Flavour and the customer's note travel in
// `notes`; a chosen drink is its own, separately priced product line.

export interface Variant {
  id: string;
  name: string;
  price: number | string; // offset on top of basePrice (Decimal arrives as a string)
  isDefault?: boolean;
}

export interface Flavour {
  id?: string;
  name: string;
  description?: string | null;
}

export interface AddonOption {
  id: string;
  name: string;
  price: number;
}

export interface MenuProduct {
  id: string;
  categoryId: string;
  name: string;
  description?: string | null;
  image?: string | null;
  basePrice: number | string;
  isBeverage?: boolean;
  variants?: Variant[];
  flavours?: Flavour[];
  // The API nests the add-on inside the product-add-on link row.
  addons?: { addon?: { id: string; name: string; price: number | string } }[];
}

/** One line of the customer's cart / a POS ticket. */
export interface OrderLine {
  id: string;
  productId: string;
  name: string;
  image?: string | null;
  variantId?: string;
  variantName?: string;
  flavour?: string;
  addons: AddonOption[];
  drinkId?: string;
  drinkName?: string;
  /** Price of the chosen drink (one per unit). */
  drinkPrice?: number;
  notes?: string;
  /** Everything priced per unit: base + size + add-ons + drink. */
  unitPrice: number;
  quantity: number;
}

export const toNumber = (v: unknown): number => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};

/** Add-ons the admin linked to a product, falling back to the shop-wide list when none are linked. */
export function addonsFor(product: MenuProduct, shopWide: AddonOption[]): AddonOption[] {
  const seen = new Set<string>();
  const out: AddonOption[] = [];
  const push = (a?: { id: string; name: string; price: number | string }) => {
    if (!a || !a.id || !a.name || seen.has(a.name.toLowerCase())) return;
    seen.add(a.name.toLowerCase());
    out.push({ id: a.id, name: a.name, price: toNumber(a.price) });
  };
  (product.addons || []).forEach((pa) => push(pa.addon));
  if (out.length === 0) shopWide.forEach(push);
  return out;
}

/** Same key = same dish; identical orders merge into one line with a higher quantity. */
export function lineKey(l: Omit<OrderLine, 'id' | 'quantity'>): string {
  return [
    l.productId,
    l.variantId || '',
    l.flavour || '',
    [...l.addons.map((a) => a.id)].sort().join(','),
    l.drinkId || '',
    (l.notes || '').trim().toLowerCase(),
  ].join('|');
}

export function composeItemNotes(l: Pick<OrderLine, 'flavour' | 'notes'>): string {
  const parts: string[] = [];
  if (l.flavour) parts.push(`Flavour: ${l.flavour}`);
  if (l.notes && l.notes.trim()) parts.push(`Note: ${l.notes.trim()}`);
  return parts.join('. ');
}

/** The `items` array for POST /orders. */
export function buildOrderItems(lines: OrderLine[]) {
  const out: Record<string, unknown>[] = [];
  for (const l of lines) {
    const notes = composeItemNotes(l);
    out.push({
      productId: l.productId,
      ...(l.variantId ? { variantId: l.variantId } : {}),
      quantity: l.quantity,
      ...(l.addons.length ? { addonIds: l.addons.map((a) => a.id) } : {}),
      ...(notes ? { notes } : {}),
    });
    // A drink is a real product: its own line so it is charged and shown on the kitchen ticket.
    if (l.drinkId) {
      out.push({ productId: l.drinkId, quantity: l.quantity, notes: `Drink for ${l.name}` });
    }
  }
  return out;
}

// ─── Estimate (server total is authoritative) ───────────────────
export const DEFAULT_TAX_PERCENT = 5;
export const DEFAULT_DELIVERY_FEE = 50;

export function estimateTotals(lines: OrderLine[], orderType: 'DELIVERY' | 'PICKUP' | 'DINE_IN', discount = 0) {
  const subtotal = lines.reduce((s, l) => s + l.unitPrice * l.quantity, 0);
  const deliveryFee = orderType === 'DELIVERY' && lines.length > 0 ? DEFAULT_DELIVERY_FEE : 0;
  const tax = subtotal * (DEFAULT_TAX_PERCENT / 100);
  const total = Math.max(0, subtotal - discount) + deliveryFee + tax;
  return { subtotal, deliveryFee, tax, total, discount };
}
