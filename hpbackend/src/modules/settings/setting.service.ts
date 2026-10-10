// ============================================================
// HungerPoint — System Settings Service
// ============================================================

import { prisma } from '../../config/database';

const DEFAULT_SETTINGS: { key: string; value: string; group: string }[] = [
  { key: 'app_name', value: 'HungerPoint', group: 'general' },
  { key: 'support_phone', value: '+92 300 0000000', group: 'general' },
  { key: 'support_email', value: 'support@hungerpoint.pk', group: 'general' },
  { key: 'currency', value: 'PKR', group: 'general' },
  { key: 'default_tax_percent', value: '5', group: 'pricing' },
  { key: 'default_delivery_fee', value: '50', group: 'pricing' },
  { key: 'unclaimed_order_alert_minutes', value: '3', group: 'delivery' },
];

export class SettingService {
  static async ensureDefaults() {
    const count = await prisma.systemSetting.count();
    if (count === 0) {
      await prisma.systemSetting.createMany({ data: DEFAULT_SETTINGS });
    }
  }

  static async getNumber(key: string, fallback: number): Promise<number> {
    const setting = await prisma.systemSetting.findUnique({ where: { key } });
    const value = setting ? Number(setting.value) : NaN;
    return Number.isFinite(value) && value >= 0 ? value : fallback;
  }

  static async getAll() {
    await this.ensureDefaults();
    return prisma.systemSetting.findMany({ orderBy: [{ group: 'asc' }, { key: 'asc' }] });
  }

  static async upsert(key: string, value: string, group?: string) {
    return prisma.systemSetting.upsert({
      where: { key },
      create: { key, value, group: group || 'general' },
      update: { value, ...(group ? { group } : {}) },
    });
  }
}
