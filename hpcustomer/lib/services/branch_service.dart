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
    this.menuCategories = const [],
  });
}

class BranchService {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  final List<Branch> branches = const [
    Branch(
      id: 'HP-G11',
      name: 'HungerPoint Main Branch - G-11 Markaz',
      address: 'Shop 12, G-11 Markaz, Islamabad',
      distance: 'Main Branch',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.6844,
      lng: 73.0039,
    ),
    Branch(
      id: 'HP-F7',
      name: 'HungerPoint F-7 Markaz',
      address: 'Plot 4-B, F-7 Markaz (Jinnah Super), Islamabad',
      distance: '1.2 KM away from you',
      isOpen: true,
      statusText: 'Open Now',
      lat: 33.7215,
      lng: 73.0567,
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
      // 1. Fetch dynamic categories from backend (admin defined)
      List<Map<String, dynamic>> dynamicMenu = [];
      try {
        final categories = await ApiService.fetchCategories();
        if (categories.isNotEmpty) {
          dynamicMenu = categories.map<Map<String, dynamic>>((c) {
            final cName = c['name']?.toString() ?? 'Category';
            final rawImg = c['image']?.toString();
            final cImg = ApiService.resolveImageUrl(rawImg);
            return {
              'id': c['id']?.toString() ?? '',
              'title': cName,
              'name': cName,
              'desc': c['description']?.toString() ?? '',
              'image': cImg,
            };
          }).toList();
        } else {
          final products = await ApiService.fetchProducts();
          if (products.isNotEmpty) {
            final seen = <String>{};
            for (final p in products) {
              final catName = (p['category'] != null && p['category']['name'] != null)
                  ? p['category']['name'].toString()
                  : 'Specialties';
              if (!seen.contains(catName)) {
                seen.add(catName);
                final images = p['images'] as List<dynamic>?;
                final rawImg = (images != null && images.isNotEmpty)
                    ? images.first.toString()
                    : p['image']?.toString();
                final imgUrl = ApiService.resolveImageUrl(rawImg);
                dynamicMenu.add({
                  'id': p['id']?.toString() ?? '',
                  'title': catName,
                  'name': p['name']?.toString() ?? 'Product',
                  'desc': catName,
                  'image': imgUrl,
                });
              }
            }
          }
        }
      } catch (pe) {
        debugPrint('Error loading dynamic categories for branches: $pe');
      }

      final list = await ApiService.fetchBranches();
      if (list.isNotEmpty) {
        final serverBranches = list.map<Branch>((b) {
          final bName = b['name']?.toString() ?? 'HungerPoint Branch';
          final bAddr = b['address']?.toString() ?? 'Islamabad';
          final double lat = double.tryParse(b['latitude']?.toString() ?? '') ?? 33.7215;
          final double lng = double.tryParse(b['longitude']?.toString() ?? '') ?? 73.0565;
          final bool isOpen = b['isOpen'] == true || (b['isOpen'] == null && b['isActive'] == true);

          return Branch(
            id: b['id'].toString(),
            name: bName,
            address: bAddr,
            distance: 'Near you',
            isOpen: isOpen,
            statusText: isOpen ? 'Open Now' : 'Closed',
            lat: lat,
            lng: lng,
            menuCategories: dynamicMenu,
          );
        }).toList();

        branchesNotifier.value = serverBranches;
        if (selectedBranchNotifier.value == null && serverBranches.isNotEmpty) {
          selectedBranchNotifier.value = serverBranches.first;
        } else if (selectedBranchNotifier.value != null) {
          final match = serverBranches.where((sb) => sb.id == selectedBranchNotifier.value!.id).firstOrNull;
          if (match != null) {
            selectedBranchNotifier.value = match;
          }
        }
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
