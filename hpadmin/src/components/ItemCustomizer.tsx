// ============================================================
// HungerPoint Web App — Item customiser (size, flavour, drink, add-ons, notes)
// ============================================================
// Used by the customer storefront and the POS so both offer exactly what the
// admin configured — same rules as the mobile app's item_detail_screen.dart:
//   • size is required when the product has sizes
//   • flavour is required when the product has flavours
//   • drinks are the products the admin flagged `isBeverage` (optional)
//   • add-ons are the ones linked to the product (else the shop-wide ones)

import { useEffect, useMemo, useState } from 'react';
import { fetchApi } from '../lib/api';
import { addonsFor, toNumber, type AddonOption, type MenuProduct, type OrderLine } from '../lib/menu';

// Menu extras rarely change, so every customiser shares one fetch per page load.
let extrasPromise: Promise<{ beverages: MenuProduct[]; addons: AddonOption[] }> | null = null;
function loadExtras() {
  if (!extrasPromise) {
    extrasPromise = Promise.all([
      fetchApi('/products').catch(() => null),
      fetchApi('/products/addons/all').catch(() => null),
    ]).then(([p, a]) => ({
      beverages: ((p?.data as MenuProduct[]) || []).filter((x) => x.isBeverage),
      addons: ((a?.data as any[]) || []).map((x) => ({ id: x.id, name: x.name, price: toNumber(x.price) })),
    }));
    extrasPromise.catch(() => {
      extrasPromise = null;
    });
  }
  return extrasPromise;
}

export function ItemCustomizer({
  product,
  initial,
  confirmLabel = 'Add to Order',
  onConfirm,
  onClose,
  resolveImage,
}: {
  product: MenuProduct;
  /** Pre-fills the form when editing an existing line. */
  initial?: Partial<OrderLine>;
  confirmLabel?: string;
  onConfirm: (line: Omit<OrderLine, 'id'>) => void;
  onClose: () => void;
  resolveImage?: (url?: string | null) => string;
}) {
  const [extras, setExtras] = useState<{ beverages: MenuProduct[]; addons: AddonOption[] }>({ beverages: [], addons: [] });
  useEffect(() => {
    let alive = true;
    loadExtras().then((e) => alive && setExtras(e));
    return () => {
      alive = false;
    };
  }, []);

  const variants = (product.variants || []).filter((v) => (v as any).isActive !== false);
  const flavours = (product.flavours || []).filter((f) => f.name);
  const addonChoices = useMemo(() => addonsFor(product, extras.addons), [product, extras.addons]);
  // A drink can't be offered with another drink.
  const drinks = product.isBeverage ? [] : extras.beverages.filter((b) => b.id !== product.id);

  const [variantId, setVariantId] = useState<string | null>(initial?.variantId ?? null);
  const [flavour, setFlavour] = useState<string | null>(initial?.flavour ?? null);
  const [drinkId, setDrinkId] = useState<string | null>(initial?.drinkId ?? null);
  const [addonIds, setAddonIds] = useState<Set<string>>(new Set((initial?.addons || []).map((a) => a.id)));
  const [notes, setNotes] = useState(initial?.notes ?? '');
  const [quantity, setQuantity] = useState(initial?.quantity ?? 1);
  const [error, setError] = useState('');

  const base = toNumber(product.basePrice);
  const variant = variants.find((v) => v.id === variantId) || null;
  const chosenAddons = addonChoices.filter((a) => addonIds.has(a.id));
  const drink = drinks.find((d) => d.id === drinkId) || null;
  const drinkPrice = drink ? toNumber(drink.basePrice) : 0;
  const unitPrice = base + (variant ? toNumber(variant.price) : 0) + chosenAddons.reduce((s, a) => s + a.price, 0) + drinkPrice;

  const submit = () => {
    if (variants.length > 0 && !variant) return setError('Please select a size.');
    if (flavours.length > 0 && !flavour) return setError('Please select a flavour.');
    onConfirm({
      productId: product.id,
      name: product.name,
      image: product.image,
      variantId: variant?.id,
      variantName: variant?.name,
      flavour: flavour || undefined,
      addons: chosenAddons,
      drinkId: drink?.id,
      drinkName: drink?.name,
      drinkPrice: drink ? drinkPrice : undefined,
      notes: notes.trim() || undefined,
      unitPrice,
      quantity,
    });
  };

  const badge = (text: string, required = false) => (
    <span
      className={`text-[10px] font-black px-2 py-0.5 rounded-md ${
        required ? 'bg-amber-500/15 text-amber-400' : 'bg-stone-800 text-stone-400'
      }`}
    >
      {text}
    </span>
  );

  const radio = (on: boolean) => (
    <span className={`w-4 h-4 rounded-full border-2 shrink-0 ${on ? 'border-amber-500 bg-amber-500 ring-2 ring-amber-500/30' : 'border-stone-600'}`} />
  );
  const check = (on: boolean) => (
    <span className={`w-4 h-4 rounded-[5px] border-2 shrink-0 flex items-center justify-center text-[10px] leading-none text-white ${on ? 'border-amber-500 bg-amber-500' : 'border-stone-600'}`}>
      {on ? '✓' : ''}
    </span>
  );

  const img = resolveImage ? resolveImage(product.image) : '';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
      <div className="w-full max-w-lg bg-stone-900 border border-stone-800 rounded-3xl overflow-hidden shadow-2xl text-stone-100 relative max-h-[92vh] flex flex-col">
        <button
          onClick={onClose}
          className="absolute top-3 right-3 z-10 text-white bg-black/60 hover:bg-black/80 w-8 h-8 rounded-full flex items-center justify-center text-sm"
          aria-label="Close"
        >
          ✕
        </button>

        {img && (
          <div className="relative h-44 w-full bg-stone-800 shrink-0">
            <img src={img} alt={product.name} className="w-full h-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-t from-stone-900 via-transparent to-black/20" />
          </div>
        )}

        <div className="p-6 overflow-y-auto space-y-6 flex-1">
          <div>
            <h3 className="text-2xl font-black text-stone-100">{product.name}</h3>
            {product.description && <p className="text-xs text-stone-400 mt-1 leading-relaxed">{product.description}</p>}
            <p className="text-sm font-black text-amber-400 mt-2">
              {variants.length > 0
                ? `Starting from PKR ${Math.min(...variants.map((v) => base + toNumber(v.price)))}`
                : `PKR ${base}`}
            </p>
          </div>

          {/* Size */}
          {variants.length > 0 && (
            <section className="space-y-2">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-extrabold text-stone-100">Variation (Size)</h4>
                {badge('REQUIRED', true)}
              </div>
              {variants.map((v) => (
                <button
                  key={v.id}
                  type="button"
                  onClick={() => {
                    setVariantId(v.id);
                    setError('');
                  }}
                  className="w-full flex items-center gap-3 py-2 text-left"
                >
                  {radio(variantId === v.id)}
                  <span className={`flex-1 text-sm ${variantId === v.id ? 'font-bold text-stone-100' : 'text-stone-300'}`}>{v.name}</span>
                  <span className="text-sm font-bold text-stone-200">PKR {base + toNumber(v.price)}</span>
                </button>
              ))}
            </section>
          )}

          {/* Flavour */}
          {flavours.length > 0 && (
            <section className="space-y-2">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-extrabold text-stone-100">Flavour Choice</h4>
                {badge('REQUIRED', true)}
              </div>
              {flavours.map((f) => (
                <button
                  key={f.name}
                  type="button"
                  onClick={() => {
                    setFlavour(f.name);
                    setError('');
                  }}
                  className="w-full flex items-start gap-3 py-2 text-left"
                >
                  <span className="mt-0.5">{radio(flavour === f.name)}</span>
                  <span className="flex-1">
                    <span className={`block text-sm ${flavour === f.name ? 'font-bold text-stone-100' : 'text-stone-300'}`}>{f.name}</span>
                    {f.description && <span className="block text-[11px] text-stone-500 mt-0.5">{f.description}</span>}
                  </span>
                </button>
              ))}
            </section>
          )}

          {/* Drink */}
          {drinks.length > 0 && (
            <section className="space-y-2">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-extrabold text-stone-100">Drink</h4>
                {badge('OPTIONAL')}
              </div>
              {drinks.map((d) => (
                <button
                  key={d.id}
                  type="button"
                  onClick={() => setDrinkId(drinkId === d.id ? null : d.id)}
                  className="w-full flex items-center gap-3 py-2 text-left"
                >
                  {radio(drinkId === d.id)}
                  <span className={`flex-1 text-sm ${drinkId === d.id ? 'font-bold text-stone-100' : 'text-stone-300'}`}>{d.name}</span>
                  <span className="text-sm font-bold text-amber-400">+PKR {toNumber(d.basePrice)}</span>
                </button>
              ))}
            </section>
          )}

          {/* Add-ons */}
          {addonChoices.length > 0 && (
            <section className="space-y-2">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-extrabold text-stone-100">Extra Add-ons & Toppings</h4>
                {badge('OPTIONAL • Multi-select')}
              </div>
              {addonChoices.map((a) => {
                const on = addonIds.has(a.id);
                return (
                  <button
                    key={a.id}
                    type="button"
                    onClick={() =>
                      setAddonIds((prev) => {
                        const next = new Set(prev);
                        if (next.has(a.id)) next.delete(a.id);
                        else next.add(a.id);
                        return next;
                      })
                    }
                    className="w-full flex items-center gap-3 py-2 text-left"
                  >
                    {check(on)}
                    <span className={`flex-1 text-sm ${on ? 'font-bold text-stone-100' : 'text-stone-300'}`}>{a.name}</span>
                    <span className="text-sm font-bold text-amber-400">+PKR {a.price}</span>
                  </button>
                );
              })}
            </section>
          )}

          {/* Notes */}
          <section className="space-y-2">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-extrabold text-stone-100">Special Instructions</h4>
              {badge('OPTIONAL')}
            </div>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
              placeholder="e.g., Less spicy, extra crispy, sauce on the side..."
              className="w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500 resize-none"
            />
          </section>
        </div>

        <div className="p-5 border-t border-stone-800 bg-stone-950 space-y-2">
          {error && <p className="text-xs font-bold text-red-400 text-center">{error}</p>}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-3 bg-stone-800 px-3 py-2 rounded-2xl border border-stone-700/60">
              <button onClick={() => setQuantity((q) => Math.max(1, q - 1))} className="text-stone-300 hover:text-white font-bold text-base w-6 text-center">
                -
              </button>
              <span className="text-sm font-extrabold text-amber-400 w-5 text-center">{quantity}</span>
              <button onClick={() => setQuantity((q) => Math.min(50, q + 1))} className="text-stone-300 hover:text-white font-bold text-base w-6 text-center">
                +
              </button>
            </div>
            <button
              onClick={submit}
              className="flex-1 py-3.5 bg-gradient-to-r from-amber-500 via-orange-600 to-red-600 hover:from-amber-600 hover:to-red-700 text-white font-extrabold text-xs rounded-2xl shadow-lg shadow-orange-500/30 transition-all active:scale-95 flex justify-between px-5"
            >
              <span>{confirmLabel}</span>
              <span>PKR {(unitPrice * quantity).toFixed(0)}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
