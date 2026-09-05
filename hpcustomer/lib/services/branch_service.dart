import 'package:flutter/foundation.dart';

class Branch {
  final String id;
  final String name;
  final String address;
  final String distance;
  final bool isOpen;
  final List<Map<String, dynamic>> menuCategories;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    this.isOpen = true,
    required this.menuCategories,
  });
}

class BranchService {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  static final List<Map<String, dynamic>> _f10Categories = [
    {
      'id': '1',
      'title': 'Thin Crust Pizza',
      'name': 'Thin Crust Beef Pepperoni',
      'desc': 'A crispy thin crust topped with beef pepperoni, mozzarella cheese, and rich marinara sauce.',
      'price': 1480,
      'image': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '20',
      'title': 'Soft Drinks',
      'name': 'Coca Cola / Sprite / Fanta 500ml',
      'desc': 'Chilled refreshing soft drinks.',
      'price': 150,
      'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '21',
      'title': 'Addons',
      'name': 'Special Garlic Mayo Dip',
      'desc': 'Signature house creamy dip sauce.',
      'price': 120,
      'image': 'https://images.unsplash.com/photo-1556742049-0a67c5574f73?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '22',
      'title': 'Side Orders',
      'name': 'Crispy Potato Fries',
      'desc': 'Golden crispy French fries seasoned with special spice blend.',
      'price': 350,
      'image': 'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '23',
      'title': 'Burgerz',
      'name': 'Crispy Zinger Burger',
      'desc': 'Succulent crispy chicken thigh fillet with fresh iceberg & spicy mayo.',
      'price': 580,
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '24',
      'title': 'Pastas',
      'name': 'Creamy Chicken Alfredo Pasta',
      'desc': 'Fettuccine pasta in rich creamy parmesan sauce topped with grilled chicken.',
      'price': 890,
      'image': 'https://images.unsplash.com/photo-1621996346565-e3d5d62817d2?auto=format&fit=crop&w=400&q=80',
    },
  ];

  static final List<Map<String, dynamic>> _swabiCategories = [
    {
      'id': '30',
      'title': 'Special Swabi Chapli Burgerz',
      'name': 'Authentic Swabi Chapli Burger',
      'desc': 'Traditional Swabi style beef chapli patty with pomegranate seeds, tomatoes, and spicy chutney.',
      'price': 650,
      'image': 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '1',
      'title': 'Thin Crust Pizza',
      'name': 'Thin Crust Beef Pepperoni',
      'desc': 'A crispy thin crust topped with beef pepperoni, mozzarella cheese, and rich marinara sauce.',
      'price': 1480,
      'image': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '24',
      'title': 'Pastas',
      'name': 'Baked Cheesy Macaroni',
      'desc': 'Oven baked macaroni with melted cheddar and mozzarella cheese.',
      'price': 790,
      'image': 'https://images.unsplash.com/photo-1621996346565-e3d5d62817d2?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '7',
      'title': 'Starters',
      'name': 'Cheezy Sticks',
      'desc': 'Freshly baked bread filled with the yummiest Cheese blend and garlic butter.',
      'price': 600,
      'image': 'https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '20',
      'title': 'Soft Drinks',
      'name': 'Chilled Soft Drink 500ml',
      'desc': 'Refreshing beverage.',
      'price': 150,
      'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '5',
      'title': 'Malai Tikka',
      'name': 'Malai Tikka Pan Pizza',
      'desc': 'Creamy BBQ Malai Tikka with mozzarella cheese.',
      'price': 1530,
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
    },
  ];

  static final List<Map<String, dynamic>> _f7Categories = [
    {
      'id': '1',
      'title': 'Thin Crust Pizza',
      'name': 'Thin Crust Beef Pepperoni',
      'desc': 'A crispy thin crust topped with beef pepperoni, mozzarella cheese, and rich marinara sauce.',
      'price': 1480,
      'image': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '5',
      'title': 'Malai Tikka',
      'name': 'Malai Tikka',
      'desc': 'A flavorful Pizza loaded with fresh BBQ Malai Tikka chunks and mozzarella cheese.',
      'price': 1530,
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '6',
      'title': 'Beef Peppero...',
      'name': 'Beef Pepperoni Pan Pizza',
      'desc': 'Freshly baked pan crust, soft inside and golden-crisp outside topped with beef pepperoni.',
      'price': 1480,
      'image': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '7',
      'title': 'Starters',
      'name': 'Cheezy Sticks',
      'desc': 'Freshly baked bread filled with the yummiest Cheese blend and garlic butter.',
      'price': 600,
      'image': 'https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '12',
      'title': 'Somewhat Local',
      'name': 'Chicken Tikka Pizza',
      'desc': 'Traditional chicken tikka topping with fresh onions and green peppers.',
      'price': 1350,
      'image': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '13',
      'title': 'Somewhat Sooper',
      'name': 'Super Supreme Pizza',
      'desc': 'Loaded with beef, chicken, black olives, mushrooms, capsicum and extra cheese.',
      'price': 1590,
      'image': 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?auto=format&fit=crop&w=400&q=80',
    },
  ];

  final List<Branch> branches = [
    Branch(
      id: 'b_f7',
      name: 'F-7 New Islamabad',
      address: 'Plot 14, Bhitai Road, F-7 Markaz, Islamabad',
      distance: '53 M away from you',
      isOpen: true,
      menuCategories: _f7Categories,
    ),
    Branch(
      id: 'b_f10',
      name: 'F-10 Markaz Islamabad',
      address: 'Plot no 2-D Sector F-10 Islamabad',
      distance: '4.8 KM away from you',
      isOpen: true,
      menuCategories: _f10Categories,
    ),
    Branch(
      id: 'b_i8',
      name: 'I-8 Markaz Islamabad',
      address: 'Shop 5, Executive Center, I-8 Markaz Islamabad',
      distance: '6.0 KM away from you',
      isOpen: true,
      menuCategories: _f10Categories,
    ),
    Branch(
      id: 'b_f11',
      name: 'F-11 Markaz Islamabad',
      address: 'Al-Hameed Mall, F-11 Markaz Islamabad',
      distance: '7.5 KM away from you',
      isOpen: true,
      menuCategories: _f7Categories,
    ),
    Branch(
      id: 'b_swabi',
      name: 'Swabi Branch',
      address: 'Main Jehangira Road, Near Bus Stand, Swabi',
      distance: '12.4 KM away from you',
      isOpen: true,
      menuCategories: _swabiCategories,
    ),
  ];

  final ValueNotifier<Branch?> selectedBranchNotifier = ValueNotifier<Branch?>(null);
  final ValueNotifier<bool> isPickupModeNotifier = ValueNotifier<bool>(false);

  Branch? get selectedBranch => selectedBranchNotifier.value;
  bool get isPickupMode => isPickupModeNotifier.value;

  void selectBranch(Branch branch) {
    selectedBranchNotifier.value = branch;
    isPickupModeNotifier.value = true;
  }

  void switchToPickup() {
    isPickupModeNotifier.value = true;
    if (selectedBranchNotifier.value == null) {
      selectedBranchNotifier.value = branches[1]; // F-10 Markaz by default
    }
  }

  void switchToDelivery() {
    isPickupModeNotifier.value = false;
  }
}
