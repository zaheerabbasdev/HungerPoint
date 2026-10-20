// ============================================================
// HungerPoint Web App — Add / edit a delivery address
// ============================================================
// Same fields as the app's new_address_form_screen: a label (Home / Work / Other),
// the address text, city and area, plus coordinates found by searching a place or
// using the current location. The server checks the coordinates against each
// branch's delivery radius when an order is placed.

import { useState } from 'react';
import { fetchApi } from '../lib/api';
import { currentPosition, reversePlace, searchPlaces, type GeoResult } from '../lib/geocode';

export interface SavedAddress {
  id: string;
  label: 'HOME' | 'WORK' | 'OTHER';
  customName?: string | null;
  address: string;
  city: string;
  area?: string | null;
  latitude?: number | string | null;
  longitude?: number | string | null;
  isDefault?: boolean;
}

export function AddressForm({
  existing,
  onSaved,
  onCancel,
}: {
  existing?: SavedAddress | null;
  onSaved: (a: SavedAddress) => void;
  onCancel: () => void;
}) {
  const [label, setLabel] = useState<SavedAddress['label']>(existing?.label ?? 'HOME');
  const [customName, setCustomName] = useState(existing?.customName ?? '');
  const [address, setAddress] = useState(existing?.address ?? '');
  const [city, setCity] = useState(existing?.city ?? 'Islamabad');
  const [area, setArea] = useState(existing?.area ?? '');
  const [lat, setLat] = useState<number | null>(existing?.latitude != null ? Number(existing.latitude) : null);
  const [lng, setLng] = useState<number | null>(existing?.longitude != null ? Number(existing.longitude) : null);
  const [isDefault, setIsDefault] = useState(existing?.isDefault ?? false);

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<GeoResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [locating, setLocating] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const runSearch = async () => {
    setSearching(true);
    setError('');
    const found = await searchPlaces(query);
    setResults(found);
    if (found.length === 0) setError('No matching place found. Try a nearby landmark or type the address below.');
    setSearching(false);
  };

  const pick = (r: GeoResult) => {
    setAddress(r.displayName);
    setLat(r.lat);
    setLng(r.lng);
    setResults([]);
    setQuery('');
  };

  const useMyLocation = async () => {
    setLocating(true);
    setError('');
    try {
      const pos = await currentPosition();
      setLat(pos.lat);
      setLng(pos.lng);
      setAddress((await reversePlace(pos.lat, pos.lng)) ?? `${pos.lat.toFixed(5)}, ${pos.lng.toFixed(5)}`);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLocating(false);
    }
  };

  const save = async () => {
    if (!address.trim()) return setError('Please enter the address.');
    setSaving(true);
    setError('');
    try {
      const body = {
        label,
        customName: label === 'OTHER' ? customName.trim() || undefined : undefined,
        address: address.trim(),
        city: city.trim() || 'Islamabad',
        area: area.trim() || undefined,
        latitude: lat ?? undefined,
        longitude: lng ?? undefined,
        isDefault,
      };
      const res = await fetchApi(existing ? `/customers/addresses/${existing.id}` : '/customers/addresses', {
        method: existing ? 'PUT' : 'POST',
        body: JSON.stringify(body),
      });
      if (res.success) onSaved(res.data);
      else setError(res.message || 'Could not save the address.');
    } catch (e: any) {
      setError(e.message || 'Could not save the address.');
    } finally {
      setSaving(false);
    }
  };

  const input = 'w-full bg-stone-800 border border-stone-700 rounded-xl px-3 py-2.5 text-xs text-stone-100 outline-none focus:border-amber-500';

  return (
    <div className="space-y-3 text-xs">
      <div className="flex gap-2">
        {(['HOME', 'WORK', 'OTHER'] as const).map((l) => (
          <button
            key={l}
            type="button"
            onClick={() => setLabel(l)}
            className={`flex-1 py-2 rounded-xl font-bold border transition-all ${
              label === l ? 'border-amber-500 bg-amber-500/10 text-amber-400' : 'border-stone-800 text-stone-400'
            }`}
          >
            {l === 'HOME' ? '🏠 Home' : l === 'WORK' ? '💼 Work' : '📍 Other'}
          </button>
        ))}
      </div>
      {label === 'OTHER' && <input className={input} value={customName} onChange={(e) => setCustomName(e.target.value)} placeholder="Name this place (e.g. Friend's house)" />}

      <div className="space-y-2">
        <div className="flex gap-2">
          <input
            className={input}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), runSearch())}
            placeholder="Search a place, e.g. G-11 Markaz Islamabad"
          />
          <button type="button" onClick={runSearch} disabled={searching || !query.trim()} className="px-3 bg-stone-800 hover:bg-stone-700 text-amber-400 font-bold rounded-xl disabled:opacity-40">
            {searching ? '…' : 'Search'}
          </button>
        </div>
        <button type="button" onClick={useMyLocation} disabled={locating} className="text-amber-400 font-bold hover:underline disabled:opacity-50">
          {locating ? 'Finding you…' : '📡 Use my current location'}
        </button>
        {results.length > 0 && (
          <ul className="bg-stone-950 border border-stone-800 rounded-xl divide-y divide-stone-800 max-h-44 overflow-y-auto">
            {results.map((r, i) => (
              <li key={i}>
                <button type="button" onClick={() => pick(r)} className="w-full text-left px-3 py-2 text-stone-300 hover:bg-stone-800">
                  📍 {r.displayName}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <textarea className={`${input} resize-none`} rows={2} value={address} onChange={(e) => setAddress(e.target.value)} placeholder="House / street / landmark" />
      <div className="grid grid-cols-2 gap-2">
        <input className={input} value={area} onChange={(e) => setArea(e.target.value)} placeholder="Area (optional)" />
        <input className={input} value={city} onChange={(e) => setCity(e.target.value)} placeholder="City" />
      </div>
      <p className={lat != null ? 'text-emerald-400 font-semibold' : 'text-stone-500'}>
        {lat != null ? '✓ Map location saved — used to pick the nearest delivering branch.' : 'No map location yet — search a place or use your current location so we can check delivery range.'}
      </p>
      <label className="flex items-center gap-2 text-stone-300 font-semibold">
        <input type="checkbox" checked={isDefault} onChange={(e) => setIsDefault(e.target.checked)} className="accent-orange-500" />
        Make this my default address
      </label>

      {error && <p className="text-red-400 font-semibold">{error}</p>}
      <div className="flex gap-2 pt-1">
        <button type="button" onClick={onCancel} className="flex-1 py-2.5 rounded-xl border border-stone-700 text-stone-300 font-bold hover:bg-stone-800">
          Cancel
        </button>
        <button type="button" onClick={save} disabled={saving} className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-orange-600 text-white font-extrabold disabled:opacity-50">
          {saving ? 'Saving…' : existing ? 'Update Address' : 'Save Address'}
        </button>
      </div>
    </div>
  );
}
