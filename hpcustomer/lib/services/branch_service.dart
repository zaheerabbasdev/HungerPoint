import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'address_service.dart';
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
  /// How far this branch delivers (km, straight line) — set by the admin.
  final double deliveryRadiusKm;
  /// Distance from the customer's address / phone, when known.
  final double? distanceKm;

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
    this.deliveryRadiusKm = 5,
    this.distanceKm,
  });

  bool deliversTo(double km) => deliveryRadiusKm <= 0 || km <= deliveryRadiusKm;

  Branch withDistance(double? km) => Branch(
        id: id,
        name: name,
        address: address,
        distance: km == null ? 'Near you' : '${km.toStringAsFixed(1)} km away',
        isOpen: isOpen,
        statusText: statusText,
        lat: lat,
        lng: lng,
        services: services,
        openingHours: openingHours,
        menuCategories: menuCategories,
        deliveryRadiusKm: deliveryRadiusKm,
        distanceKm: km,
      );
}

/// Great-circle distance in km — the same formula the backend uses for the
/// delivery-radius check, so the app and server agree on who delivers where.
double distanceKmBetween(double lat1, double lng1, double lat2, double lng2) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class BranchService {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  final ValueNotifier<Branch?> selectedBranchNotifier = ValueNotifier<Branch?>(null);
  final ValueNotifier<bool> isPickupModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<Branch>> branchesNotifier = ValueNotifier<List<Branch>>([]);

  Branch? get selectedBranch =>
      selectedBranchNotifier.value ?? (branchesNotifier.value.isNotEmpty ? branchesNotifier.value.first : null);
  bool get isPickupMode => isPickupModeNotifier.value;
  List<Branch> get allBranches => branchesNotifier.value;

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
          final bAddr = b['address']?.toString() ?? '';
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
            deliveryRadiusKm: double.tryParse(b['deliveryRadius']?.toString() ?? '') ?? 5,
          );
        }).toList();

        branchesNotifier.value = serverBranches;
        await refreshDistances();
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

  /// Where the customer is: the chosen delivery address, else the phone's
  /// location (only if permission was already given — never prompts here).
  Future<({double lat, double lng})?> _referencePoint() async {
    final saved = AddressService().selectedAddress;
    final lat = saved?.latitude ?? AddressService().temporaryLatitude;
    final lng = saved?.longitude ?? AddressService().temporaryLongitude;
    if (lat != null && lng != null) return (lat: lat, lng: lng);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return null;
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 5)),
          );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Fills in each branch's real distance and sorts the list nearest-first.
  Future<void> refreshDistances() async {
    final here = await _referencePoint();
    if (here == null || branchesNotifier.value.isEmpty) return;
    final updated = branchesNotifier.value
        .map((b) => b.withDistance(distanceKmBetween(here.lat, here.lng, b.lat, b.lng)))
        .toList()
      ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    branchesNotifier.value = updated;
    final selectedId = selectedBranchNotifier.value?.id;
    final match = updated.where((b) => b.id == selectedId).firstOrNull;
    if (match != null) selectedBranchNotifier.value = match;
  }

  /// Nearest branch (after [refreshDistances]); the first one otherwise.
  Branch? get nearestBranch => allBranches.isNotEmpty ? allBranches.first : null;

  /// The closest open branch whose delivery radius covers this point, or null
  /// when no branch delivers there.
  Branch? bestBranchFor(double lat, double lng) {
    Branch? best;
    double bestKm = double.infinity;
    for (final b in allBranches) {
      if (!b.isOpen) continue;
      final km = distanceKmBetween(lat, lng, b.lat, b.lng);
      if (b.deliversTo(km) && km < bestKm) {
        best = b.withDistance(km);
        bestKm = km;
      }
    }
    return best;
  }

  void selectBranch(Branch branch) {
    selectedBranchNotifier.value = branch;
    isPickupModeNotifier.value = true;
  }

  void switchToPickup() {
    isPickupModeNotifier.value = true;
    if (selectedBranchNotifier.value == null && allBranches.isNotEmpty) {
      selectedBranchNotifier.value = allBranches.first;
    }
  }

  void switchToDelivery() {
    isPickupModeNotifier.value = false;
  }
}
