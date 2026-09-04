// ============================================================
// HungerPoint — Comprehensive Database Seed Script
// Database: hungerpointdb (MySQL)
// ============================================================

import { PrismaClient, UserRole, OrderType, PaymentMethod, RiderStatus } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting HungerPoint database seeding...');

  const passwordHash = await bcrypt.hash('Admin@123456', 12);
  const customerPassword = await bcrypt.hash('Customer@123456', 12);

  // 1. Create Branches
  console.log('📍 Seeding Branches...');
  const mainBranch = await prisma.branch.upsert({
    where: { code: 'HP-G11' },
    update: {},
    create: {
      name: 'HungerPoint Main Branch - G-11 Markaz',
      code: 'HP-G11',
      address: 'Shop 12, G-11 Markaz',
      city: 'Islamabad',
      area: 'G-11',
      latitude: 33.6844,
      longitude: 73.0039,
      phone: '+923001234567',
      email: 'g11@hungerpoint.pk',
      deliveryRadius: 8.0,
      isOpen: true,
      isActive: true,
    },
  });

  const F7Branch = await prisma.branch.upsert({
    where: { code: 'HP-F7' },
    update: {},
    create: {
      name: 'HungerPoint F-7 Markaz',
      code: 'HP-F7',
      address: 'Plot 4-B, F-7 Markaz (Jinnah Super)',
      city: 'Islamabad',
      area: 'F-7',
      latitude: 33.7215,
      longitude: 73.0567,
      phone: '+923007654321',
      email: 'f7@hungerpoint.pk',
      deliveryRadius: 10.0,
      isOpen: true,
      isActive: true,
    },
  });

  // 2. Create Users
  console.log('👤 Seeding Users & Roles...');
  const superAdmin = await prisma.user.upsert({
    where: { phone: '+923000000001' },
    update: {},
    create: {
      name: 'Super Administrator',
      email: 'admin@hungerpoint.pk',
      phone: '+923000000001',
      password: passwordHash,
      role: UserRole.SUPER_ADMIN,
      isVerified: true,
    },
  });

  const branchManager = await prisma.user.upsert({
    where: { phone: '+923000000002' },
    update: {},
    create: {
      name: 'Manager G11',
      email: 'manager.g11@hungerpoint.pk',
      phone: '+923000000002',
      password: passwordHash,
      role: UserRole.BRANCH_MANAGER,
      branchId: mainBranch.id,
      isVerified: true,
    },
  });

  const kitchenStaff = await prisma.user.upsert({
    where: { phone: '+923000000003' },
    update: {},
    create: {
      name: 'Chef Tariq',
      email: 'chef.g11@hungerpoint.pk',
      phone: '+923000000003',
      password: passwordHash,
      role: UserRole.KITCHEN_STAFF,
      branchId: mainBranch.id,
      isVerified: true,
    },
  });

  const riderUser = await prisma.user.upsert({
    where: { phone: '+923000000004' },
    update: {},
    create: {
      name: 'Rider Kamran',
      email: 'kamran.rider@hungerpoint.pk',
      phone: '+923000000004',
      password: passwordHash,
      role: UserRole.RIDER,
      branchId: mainBranch.id,
      isVerified: true,
    },
  });

  // Rider Profile
  await prisma.rider.upsert({
    where: { userId: riderUser.id },
    update: {},
    create: {
      userId: riderUser.id,
      branchId: mainBranch.id,
      status: RiderStatus.ONLINE,
      vehicle: 'Honda CD 70',
      licensePlate: 'ICT-B-4921',
    },
  });

  const customerUser = await prisma.user.upsert({
    where: { phone: '+923009999999' },
    update: {},
    create: {
      name: 'Ahmed Khan',
      email: 'ahmed@gmail.com',
      phone: '+923009999999',
      password: customerPassword,
      role: UserRole.CUSTOMER,
      isVerified: true,
    },
  });

  const customerProfile = await prisma.customer.upsert({
    where: { userId: customerUser.id },
    update: {},
    create: {
      userId: customerUser.id,
    },
  });

  // Loyalty account for customer
  await prisma.loyaltyAccount.upsert({
    where: { customerId: customerProfile.id },
    update: {},
    create: {
      customerId: customerProfile.id,
      points: 150,
      lifetime: 250,
    },
  });

  // Customer Address
  await prisma.address.create({
    data: {
      customerId: customerProfile.id,
      label: 'HOME',
      customName: 'Home Apartment',
      address: 'Flat 402, Al-Rehman Heights, G-11/3',
      city: 'Islamabad',
      area: 'G-11',
      isDefault: true,
    },
  });

  // 3. Categories & Products
  console.log('🍔 Seeding Menu Categories & Products...');
  
  const burgerCategory = await prisma.category.upsert({
    where: { name: 'Gourmet Burgers' },
    update: {},
    create: {
      name: 'Gourmet Burgers',
      description: 'Juicy 100% beef and crisp chicken burgers with handmade artisan buns',
      image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
      sortOrder: 1,
    },
  });

  const pizzaCategory = await prisma.category.upsert({
    where: { name: 'Artisan Pizzas' },
    update: {},
    create: {
      name: 'Artisan Pizzas',
      description: 'Freshly baked wood-fired pizzas with premium melted mozzarella',
      image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80',
      sortOrder: 2,
    },
  });

  const drinksCategory = await prisma.category.upsert({
    where: { name: 'Beverages & Shakes' },
    update: {},
    create: {
      name: 'Beverages & Shakes',
      description: 'Chilled soft drinks, gourmet thick shakes, and fresh fruit juices',
      image: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
      sortOrder: 3,
    },
  });

  // Products
  const zinger = await prisma.product.create({
    data: {
      categoryId: burgerCategory.id,
      name: 'Zinger Crunch Burger',
      description: 'Crispy fried chicken breast filet topped with signature spicy mayo, lettuce, and cheese',
      basePrice: 550.0,
      image: 'https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?auto=format&fit=crop&w=800&q=80',
      sortOrder: 1,
      variants: {
        create: [
          { name: 'Single Filet', price: 0, isDefault: true, sortOrder: 1 },
          { name: 'Double Filet Jumbo', price: 250.0, sortOrder: 2 },
        ],
      },
    },
  });

  const smashBurger = await prisma.product.create({
    data: {
      categoryId: burgerCategory.id,
      name: 'Smokey Beef Smash Burger',
      description: 'Double smashed beef patties with caramelized onions, cheddar, and smoky BBQ sauce',
      basePrice: 790.0,
      image: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80',
      sortOrder: 2,
    },
  });

  const pepperoniPizza = await prisma.product.create({
    data: {
      categoryId: pizzaCategory.id,
      name: 'Loaded Pepperoni Pizza',
      description: 'Italian beef pepperoni slices on rich marinara sauce with extra mozzarella cheese',
      basePrice: 1290.0,
      image: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=800&q=80',
      sortOrder: 1,
      variants: {
        create: [
          { name: 'Medium 10"', price: 0, isDefault: true, sortOrder: 1 },
          { name: 'Large 14"', price: 500.0, sortOrder: 2 },
          { name: 'Party 16"', price: 900.0, sortOrder: 3 },
        ],
      },
    },
  });

  // 4. Create Addons
  console.log('🧀 Seeding Addons...');
  const extraCheese = await prisma.addon.create({
    data: { name: 'Extra Cheddar Cheese Slice', price: 80.0 },
  });
  const friesAddon = await prisma.addon.create({
    data: { name: 'Side Fries & Dip', price: 180.0 },
  });

  // Link Addons to Products
  await prisma.productAddon.createMany({
    data: [
      { productId: zinger.id, addonId: extraCheese.id },
      { productId: zinger.id, addonId: friesAddon.id },
      { productId: smashBurger.id, addonId: extraCheese.id },
      { productId: smashBurger.id, addonId: friesAddon.id },
    ],
  });

  // 5. Create Sample Order
  console.log('📦 Seeding Sample Order...');
  await prisma.order.create({
    data: {
      orderNumber: 'HP-849201',
      customerId: customerProfile.id,
      branchId: mainBranch.id,
      status: 'DELIVERED',
      type: OrderType.DELIVERY,
      paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
      subtotal: 1340.0,
      deliveryFee: 50.0,
      tax: 67.0,
      total: 1457.0,
      items: {
        create: [
          {
            productId: zinger.id,
            quantity: 2,
            unitPrice: 550.0,
            variantPrice: 0.0,
            totalPrice: 1100.0,
          },
        ],
      },
      statusHistory: {
        create: [
          { status: 'PENDING', notes: 'Order placed via Web App' },
          { status: 'CONFIRMED', notes: 'Order accepted by G-11 Manager' },
          { status: 'PREPARING', notes: 'Kitchen started cooking' },
          { status: 'READY', notes: 'Ready for rider pickup' },
          { status: 'OUT_FOR_DELIVERY', notes: 'Kamran picked up order' },
          { status: 'DELIVERED', notes: 'Delivered to customer' },
        ],
      },
    },
  });

  console.log('✅ HungerPoint Database Seeding Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
