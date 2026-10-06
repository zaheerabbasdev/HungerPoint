// ============================================================
// HungerPoint — Branch reference check
// ============================================================

import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';

/** Rejects a branch id that doesn't exist (or was deactivated) with a clear 400. */
export const assertBranchAvailable = async (branchId: string | null | undefined): Promise<void> => {
  if (!branchId) throw new AppError('Please choose a branch', 400);
  const branch = await prisma.branch.findUnique({ where: { id: branchId }, select: { isActive: true } });
  if (!branch || !branch.isActive) throw new AppError('The selected branch does not exist or is no longer active', 400);
};
