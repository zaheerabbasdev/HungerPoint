// ============================================================
// HungerPoint — Inventory Service
// ============================================================

import { prisma } from '../../config/database';
import { InventoryTransactionType } from '@prisma/client';

export class InventoryService {
  static async getBranchInventory(branchId: string) {
    return prisma.inventoryStock.findMany({
      where: { branchId },
      include: {
        item: true,
        branch: { select: { name: true } },
      },
    });
  }

  static async addInventoryItem(data: { name: string; unit: string; minStock?: number; description?: string }) {
    return prisma.inventoryItem.create({ data });
  }

  static async updateStock(data: {
    itemId: string;
    branchId: string;
    type: InventoryTransactionType;
    quantity: number;
    notes?: string;
    createdBy?: string;
  }) {
    const { itemId, branchId, type, quantity, notes, createdBy } = data;

    // Record transaction
    await prisma.inventoryTransaction.create({
      data: { itemId, branchId, type, quantity, notes, createdBy },
    });

    // Determine stock change delta
    let delta = quantity;
    if (
      type === InventoryTransactionType.STOCK_OUT ||
      type === InventoryTransactionType.CONSUMPTION ||
      type === InventoryTransactionType.WASTE ||
      type === InventoryTransactionType.TRANSFER_OUT
    ) {
      delta = -quantity;
    }

    const currentStock = await prisma.inventoryStock.findUnique({
      where: { itemId_branchId: { itemId, branchId } },
    });

    const newQuantity = Number(currentStock?.quantity || 0) + delta;

    return prisma.inventoryStock.upsert({
      where: { itemId_branchId: { itemId, branchId } },
      update: { quantity: newQuantity },
      create: { itemId, branchId, quantity: newQuantity },
      include: { item: true },
    });
  }
}
