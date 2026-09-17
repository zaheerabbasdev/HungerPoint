// ============================================================
// HungerPoint Backend — Customer Service
// ============================================================

import { prisma } from '../../config/database';
import { AddressLabel } from '@prisma/client';

export class CustomerService {
  /**
   * Ensure customer record exists for the given user ID
   */
  static async getOrCreateCustomer(userId: string) {
    let customer = await prisma.customer.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!customer) {
      customer = await prisma.customer.create({
        data: { userId },
        include: { user: true },
      });
    }

    return customer;
  }

  /**
   * Get all active addresses for customer
   */
  static async getAddresses(customerId: string) {
    return prisma.address.findMany({
      where: { customerId, isActive: true },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
  }

  /**
   * Add new delivery address
   */
  static async addAddress(customerId: string, data: {
    label?: AddressLabel;
    customName?: string;
    address: string;
    city?: string;
    area?: string;
    latitude?: number;
    longitude?: number;
    isDefault?: boolean;
  }) {
    if (data.isDefault) {
      // Unset previous defaults
      await prisma.address.updateMany({
        where: { customerId, isDefault: true },
        data: { isDefault: false },
      });
    }

    return prisma.address.create({
      data: {
        customerId,
        label: data.label || AddressLabel.HOME,
        customName: data.customName,
        address: data.address,
        city: data.city || 'Islamabad',
        area: data.area,
        latitude: data.latitude !== undefined ? data.latitude : null,
        longitude: data.longitude !== undefined ? data.longitude : null,
        isDefault: data.isDefault ?? false,
      },
    });
  }

  /**
   * Update address
   */
  static async updateAddress(addressId: string, customerId: string, data: {
    label?: AddressLabel;
    customName?: string;
    address?: string;
    city?: string;
    area?: string;
    latitude?: number;
    longitude?: number;
    isDefault?: boolean;
  }) {
    if (data.isDefault) {
      await prisma.address.updateMany({
        where: { customerId, isDefault: true },
        data: { isDefault: false },
      });
    }

    return prisma.address.update({
      where: { id: addressId },
      data: {
        ...data,
        latitude: data.latitude !== undefined ? data.latitude : undefined,
        longitude: data.longitude !== undefined ? data.longitude : undefined,
      },
    });
  }

  /**
   * Delete address (soft delete by setting isActive: false)
   */
  static async deleteAddress(addressId: string, customerId: string) {
    return prisma.address.update({
      where: { id: addressId },
      data: { isActive: false },
    });
  }

  /**
   * Get customer profile
   */
  static async getProfile(userId: string) {
    const customer = await this.getOrCreateCustomer(userId);
    const addresses = await this.getAddresses(customer.id);

    return {
      id: customer.id,
      userId: customer.userId,
      name: customer.user.name,
      email: customer.user.email,
      phone: customer.user.phone,
      profileImage: customer.user.profileImage,
      dateOfBirth: customer.dateOfBirth,
      avatarEmoji: customer.avatarEmoji,
      totalOrders: customer.totalOrders,
      totalSpent: customer.totalSpent,
      addresses,
    };
  }

  /**
   * Update customer profile
   */
  static async updateProfile(userId: string, data: {
    name?: string;
    email?: string;
    phone?: string;
    profileImage?: string;
    dateOfBirth?: string | Date;
    avatarEmoji?: string;
  }) {
    const updateUserData: any = {};
    if (data.name !== undefined) updateUserData.name = data.name;
    if (data.email !== undefined) updateUserData.email = data.email;
    if (data.phone !== undefined) updateUserData.phone = data.phone;
    if (data.profileImage !== undefined) updateUserData.profileImage = data.profileImage;

    if (Object.keys(updateUserData).length > 0) {
      await prisma.user.update({
        where: { id: userId },
        data: updateUserData,
      });
    }

    if (data.dateOfBirth !== undefined || data.avatarEmoji !== undefined) {
      await prisma.customer.upsert({
        where: { userId },
        create: {
          userId,
          dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : null,
          avatarEmoji: data.avatarEmoji,
        },
        update: {
          ...(data.dateOfBirth !== undefined ? { dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : null } : {}),
          ...(data.avatarEmoji !== undefined ? { avatarEmoji: data.avatarEmoji } : {}),
        },
      });
    }

    return this.getProfile(userId);
  }

  /**
   * Search for a customer by phone number (staff-only, used by POS/phone orders).
   */
  static async searchByPhone(phone: string) {
    const user = await prisma.user.findFirst({
      where: { phone: { contains: phone }, role: 'CUSTOMER', isActive: true },
    });
    if (!user) return null;

    const customer = await this.getOrCreateCustomer(user.id);
    return {
      customerId: customer.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
    };
  }

  /**
   * Deactivate (soft-delete) the customer's account.
   * Sets User.isActive = false, which blocks future login/refresh (see auth.service.ts).
   */
  static async deactivateAccount(userId: string) {
    await prisma.user.update({
      where: { id: userId },
      data: { isActive: false },
    });
    await prisma.refreshToken.deleteMany({ where: { userId } });
  }
}
