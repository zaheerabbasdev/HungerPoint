import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Represents a saved delivery address with label, full text, and id
class SavedAddress {
  final String id;
  final String label; // "Home", "Work", "Other", or custom
  final String address;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedAddress &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Service to store saved addresses and active delivery address.
class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  /// List of saved addresses (populated dynamically from backend)
  final ValueNotifier<List<SavedAddress>> savedAddressesNotifier =
      ValueNotifier<List<SavedAddress>>([]);

  /// Currently selected address
  final ValueNotifier<SavedAddress?> selectedAddressNotifier =
      ValueNotifier<SavedAddress?>(null);

  /// One-time / temporary chosen location (from Choose Location).
  /// Not saved into [savedAddressesNotifier].
  final ValueNotifier<String?> customLocationNotifier = ValueNotifier<String?>(null);

  /// Backward-compatible notifier for string listeners
  final ValueNotifier<String?> addressNotifier = ValueNotifier<String?>(null);

  SavedAddress? get selectedAddress => selectedAddressNotifier.value;
  String? get currentAddress =>
      customLocationNotifier.value ?? selectedAddressNotifier.value?.label ?? addressNotifier.value;
  List<SavedAddress> get savedAddresses => savedAddressesNotifier.value;

  /// The active delivery label displayed on top header (e.g. "Work", "Home", or "House123")
  String get activeDeliveryLabel {
    if (customLocationNotifier.value != null && customLocationNotifier.value!.trim().isNotEmpty) {
      return customLocationNotifier.value!.trim();
    }
    return selectedAddressNotifier.value?.label ?? (savedAddresses.isNotEmpty ? savedAddresses.first.label : 'Select Address');
  }

  bool get hasActiveLocation =>
      (customLocationNotifier.value != null && customLocationNotifier.value!.trim().isNotEmpty) ||
      selectedAddressNotifier.value != null;

  /// Sets a temporary / one-time selected location (from Choose Location).
  /// This updates the header "Deliver to [location]", but is NOT added to
  /// the saved addresses list in the bottom sheet.
  void setTemporaryLocation(String location) {
    selectedAddressNotifier.value = null; // deselect saved address radio
    customLocationNotifier.value = location;
    addressNotifier.value = location;
  }

  /// Select an address
  void selectAddress(SavedAddress address) {
    customLocationNotifier.value = null; // clear any temporary location
    selectedAddressNotifier.value = address;
    addressNotifier.value = address.label;
  }

  /// Load addresses from backend database
  Future<void> fetchAddressesFromBackend() async {
    try {
      final list = await ApiService.getAddresses();
      if (list.isNotEmpty) {
        final serverAddresses = list.map<SavedAddress>((item) {
          return SavedAddress(
            id: item['id']?.toString() ?? '',
            label: item['title']?.toString() ?? 'Home',
            address: item['address']?.toString() ?? '',
          );
        }).toList();

        savedAddressesNotifier.value = serverAddresses;
        if (selectedAddressNotifier.value == null && serverAddresses.isNotEmpty) {
          selectAddress(serverAddresses.first);
        }
      }
    } catch (e) {
      debugPrint('Error loading saved addresses from backend: $e');
    }
  }

  /// Add a new address (Home, Work, Other, etc.)
  void addAddress({
    required String label,
    required String address,
    bool selectImmediately = true,
  }) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final item = SavedAddress(
      id: newId,
      label: label,
      address: address,
    );
    savedAddressesNotifier.value = [...savedAddressesNotifier.value, item];
    if (selectImmediately) {
      selectAddress(item);
    }
    // Sync with backend API
    ApiService.addAddress({'title': label, 'address': address});
  }

  /// Delete address
  void deleteAddress(String id) {
    savedAddressesNotifier.value = savedAddressesNotifier.value.where((a) => a.id != id).toList();
    if (selectedAddressNotifier.value?.id == id) {
      selectedAddressNotifier.value = savedAddressesNotifier.value.isNotEmpty ? savedAddressesNotifier.value.first : null;
    }
    ApiService.deleteAddress(id);
  }

  /// Legacy helper
  void setAddress(String address, {String label = 'Home'}) {
    addAddress(label: label, address: address, selectImmediately: true);
  }

  /// Update an existing saved address
  void updateAddress({
    required String id,
    required String label,
    required String address,
  }) {
    final updatedList = savedAddressesNotifier.value.map((item) {
      if (item.id == id) {
        return SavedAddress(id: id, label: label, address: address);
      }
      return item;
    }).toList();

    savedAddressesNotifier.value = updatedList;

    // If currently selected address is the one updated, update selected address as well
    if (selectedAddressNotifier.value?.id == id) {
      final updated = updatedList.firstWhere((a) => a.id == id);
      selectedAddressNotifier.value = updated;
      addressNotifier.value = updated.label;
    }
  }

  /// Check if an address with the given label already exists, excluding a given id
  bool hasAddressWithLabelExcludingId(String label, String id) {
    return savedAddressesNotifier.value.any(
      (a) => a.id != id && a.label.trim().toLowerCase() == label.trim().toLowerCase(),
    );
  }

  /// Check if an address with the given label already exists (case-insensitive)
  bool hasAddressWithLabel(String label) {
    return savedAddressesNotifier.value.any(
      (a) => a.label.trim().toLowerCase() == label.trim().toLowerCase(),
    );
  }

  void clearAddress() {
    customLocationNotifier.value = null;
    selectedAddressNotifier.value = null;
    addressNotifier.value = null;
  }
}
