// ============================================================
// HungerPoint — Email / phone normalisation for account identifiers
// ============================================================

import { AppError } from '../middleware/error.middleware';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

/** Emails are matched case-insensitively, so store and look them up in lower case. */
export const normalizeEmail = (value: string): string => value.trim().toLowerCase();

/**
 * Turns common Pakistani formats into E.164 (+923001234567):
 * 0300 1234567 · 03001234567 · 923001234567 · 3001234567 · 0092300… · +92 300-1234567.
 * Numbers that already start with another country's "+" are kept as typed (minus separators).
 */
export const normalizePhone = (value: string): string => {
  let v = value.trim().replace(/[\s\-().]/g, '');
  if (v.startsWith('+')) return v;
  if (v.startsWith('00')) return `+${v.slice(2)}`;
  if (v.startsWith('92') && v.length >= 12) return `+${v}`;
  if (v.startsWith('0')) return `+92${v.slice(1)}`;
  if (v.startsWith('3') && v.length === 10) return `+92${v}`;
  return v;
};

export const isValidEmail = (value: string): boolean => EMAIL_PATTERN.test(value);

export const isValidPhone = (value: string): boolean => /^\+\d{10,15}$/.test(value);

/** Staff accounts sign in with their email, so one is mandatory. */
export const requireEmail = (value: unknown): string => {
  const email = typeof value === 'string' ? normalizeEmail(value) : '';
  if (!isValidEmail(email)) throw new AppError('A valid email address is required', 400);
  return email;
};

export const requirePhone = (value: unknown): string => {
  const phone = typeof value === 'string' ? normalizePhone(value) : '';
  if (!isValidPhone(phone)) throw new AppError('A valid phone number is required', 400);
  return phone;
};

/**
 * Every way the same Pakistani number may be stored in the database:
 * +923001234567, 03001234567, 923001234567 or 3001234567. Accounts created
 * before numbers were normalised keep their original format, so lookups and
 * duplicate checks have to consider all of them.
 */
export const phoneVariants = (value: string): string[] => {
  const normalized = normalizePhone(value);
  const variants = new Set<string>([normalized]);
  if (normalized.startsWith('+92')) {
    const national = normalized.slice(3);
    variants.add(`0${national}`);
    variants.add(`92${national}`);
    variants.add(national);
  }
  return [...variants];
};
