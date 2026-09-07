import 'package:flutter/foundation.dart';
import 'api_service.dart';

class Branch {
  final String id;
  final String name;
  final String address;
  final String distance;
  final bool isOpen;
  final String statusText;
  final double lat;
  final double lng;
  final List<String> services;
  final Map<String, String> openingHours;
  final List<Map<String, dynamic>> menuCategories;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    this.isOpen = true,
    this.statusText = 'Open Now',
    this.lat = 33.7215,
    this.lng = 73.0565,
    this.services = const ['DINE IN', 'DELIVERY', 'PICK-UP'],
    this.openingHours = const {
      'Monday - Thursday': '11:00AM - 03:00AM',
      'Friday': '02:00PM - 03:00AM',
      'Saturday - Sunday': '11:00AM - 03:00AM',
    },
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
      id: 'b_f7_old',
      name: 'F-7 Old Islamabad',
      address: 'Shop 2, School Road, F-7 Markaz, Islamabad',
      distance: '19 M away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.7218,
      lng: 73.0568,
      menuCategories: _f7Categories,
    ),
    Branch(
      id: 'b_f7',
      name: 'F-7 New Islamabad',
      address: 'Plot 14, Bhitai Road, F-7 Markaz, Islamabad',
      distance: '53 M away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.7215,
      lng: 73.0565,
      menuCategories: _f7Categories,
    ),
    Branch(
      id: 'b_centaurus',
      name: 'Centaurus Mall',
      address: 'Food Court, 4th Floor, Centaurus Mall, Jinnah Avenue, Islamabad',
      distance: '1.4 KM away from you',
      isOpen: false,
      statusText: 'Branch is closed today',
      lat: 33.7077,
      lng: 73.0501,
      menuCategories: _f10Categories,
    ),
    Branch(
      id: 'b_f10',
      name: 'F-10 Markaz Islamabad',
      address: 'Plot no 2-D Sector F-10 Islamabad',
      distance: '4.8 KM away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.6934,
      lng: 73.0116,
      menuCategories: _f10Categories,
    ),
    Branch(
      id: 'b_i8',
      name: 'I-8 Markaz Islamabad',
      address: 'Shop 5, Executive Center, I-8 Markaz Islamabad',
      distance: '6.0 KM away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.6685,
      lng: 73.0763,
      menuCategories: _f10Categories,
    ),
    Branch(
      id: 'b_f11',
      name: 'F-11 Markaz Islamabad',
      address: 'Al-Hameed Mall, F-11 Markaz Islamabad',
      distance: '7.5 KM away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.6841,
      lng: 72.9882,
      menuCategories: _f7Categories,
    ),
    Branch(
      id: 'b_swabi',
      name: 'Swabi Branch',
      address: 'Main Jehangira Road, Near Bus Stand, Swabi',
      distance: '12.4 KM away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 34.1202,
      lng: 72.4706,
      menuCategories: _swabiCategories,
    ),
  ];

  final ValueNotifier<Branch?> selectedBranchNotifier = ValueNotifier<Branch?>(null);
  final ValueNotifier<bool> isPickupModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<Branch>> branchesNotifier = ValueNotifier<List<Branch>>([]);

  Branch? get selectedBranch => selectedBranchNotifier.value;
  bool get isPickupMode => isPickupModeNotifier.value;
  List<Branch> get allBranches => branchesNotifier.value.isNotEmpty ? branchesNotifier.value : branches;

  Future<void> fetchBranchesFromBackend() async {
    try {
      // Fetch live products for branch menus
      List<Map<String, dynamic>> dynamicMenu = [];
      try {
        final products = await ApiService.fetchProducts();
        if (products.isNotEmpty) {
          dynamicMenu = products.map<Map<String, dynamic>>((p) {
            final catName = (p['category'] != null && p['category']['name'] != null)
                ? p['category']['name'].toString()
                : 'Specialties';
            final images = p['images'] as List<dynamic>?;
            final imgUrl = (images != null && images.isNotEmpty)
                ? images.first.toString()
                : 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80';
            final num priceNum = p['basePrice'] ?? p['price'] ?? 0;

            return {
              'id': p['id'].toString(),
              'title': catName,
              'name': p['name']?.toString() ?? 'Product',
              'desc': p['description']?.toString() ?? '',
              'price': priceNum.toInt(),
              'image': imgUrl,
            };
          }).toList();
        }
      } catch (pe) {
        debugPrint('Error loading dynamic products for branches: $pe');
      }

      final list = await ApiService.fetchBranches();
      if (list.isNotEmpty) {
        final serverBranches = list.map<Branch>((b) {
          final bName = b['name']?.toString() ?? 'HungerPoint Branch';
          final bAddr = b['address']?.toString() ?? 'Islamabad';
          final num lat = b['latitude'] ?? 33.7215;
          final num lng = b['longitude'] ?? 73.0565;
          final bool isActive = b['isActive'] ?? true;

          return Branch(
            id: b['id'].toString(),
            name: bName,
            address: bAddr,
            distance: 'Near you',
            isOpen: isActive,
            statusText: isActive ? 'Open Now' : 'Closed',
            lat: lat.toDouble(),
            lng: lng.toDouble(),
            menuCategories: dynamicMenu.isNotEmpty ? dynamicMenu : _f10Categories,
          );
        }).toList();

        branchesNotifier.value = serverBranches;
      }
    } catch (e) {
      debugPrint('Error fetching branches from backend: $e');
    }
  }

  void selectBranch(Branch branch) {
    selectedBranchNotifier.value = branch;
    isPickupModeNotifier.value = true;
  }

  void switchToPickup() {
    isPickupModeNotifier.value = true;
    if (selectedBranchNotifier.value == null) {
      final list = allBranches;
      selectedBranchNotifier.value = list.length > 1 ? list[1] : list.first;
    }
  }

  void switchToDelivery() {
    isPickupModeNotifier.value = false;
  }
}
