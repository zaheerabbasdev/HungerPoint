// ============================================================
// HungerPoint — Account identity (email / phone) uniqueness
// ============================================================

import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { phoneVariants } from '../../utils/identity';

const describe = (user: { name: string; role: string }) => `${user.role.toLowerCase().replace(/_/g, ' ')} "${user.name}"`;

/**
 * Refuses an email or phone number that another account already uses, with a
 * message that says which account has it. `exceptUserId` lets an account keep
 * its own details when it is edited.
 */
export const assertIdentityAvailable = async (
  identity: { email?: string; phone?: string },
  exceptUserId?: string,
): Promise<void> => {
  const notSelf = exceptUserId ? { id: { not: exceptUserId } } : {};

  if (identity.email) {
    const owner = await prisma.user.findFirst({ where: { email: identity.email, ...notSelf }, select: { name: true, role: true } });
    if (owner) throw new AppError(`This email is already used by ${describe(owner)}.`, 409);
  }

  if (identity.phone) {
    const owner = await prisma.user.findFirst({
      where: { phone: { in: phoneVariants(identity.phone) }, ...notSelf },
      select: { name: true, role: true },
    });
    if (owner) {
      const hint = owner.role === 'RIDER' ? ' Open that rider and use Edit to add an email instead of creating a new one.' : '';
      throw new AppError(`This phone number already belongs to ${describe(owner)}.${hint}`, 409);
    }
  }
};
