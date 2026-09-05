import 'package:flutter/foundation.dart';

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

  /// List of saved addresses (Home, Work, Other)
  final ValueNotifier<List<SavedAddress>> savedAddressesNotifier =
      ValueNotifier<List<SavedAddress>>([
    const SavedAddress(
      id: 'home_1',
      label: 'Home',
      address: 'Cheezious, Street 1, F 7 Markaz, F 7, Islamabad, Islamabad Capital Territory',
    ),
    const SavedAddress(
      id: 'work_1',
      label: 'Work',
      address: 'Executive Guest House, Bhitai Road, F 7/1, F 7, Islamabad, Islamabad Capital Territory',
    ),
    const SavedAddress(
      id: 'other_1',
      label: 'Other',
      address: 'House 45, Street 12, G-11/2, Islamabad, Islamabad Capital Territory',
    ),
  ]);

  /// Currently selected address
  final ValueNotifier<SavedAddress?> selectedAddressNotifier =
      ValueNotifier<SavedAddress?>(
    const SavedAddress(
      id: 'work_1',
      label: 'Work',
      address: 'Executive Guest House, Bhitai Road, F 7/1, F 7, Islamabad, Islamabad Capital Territory',
    ),
  );

  /// One-time / temporary chosen location (from Choose Location).
  /// Not saved into [savedAddressesNotifier].
  final ValueNotifier<String?> customLocationNotifier = ValueNotifier<String?>(null);

  /// Backward-compatible notifier for string listeners
  final ValueNotifier<String?> addressNotifier = ValueNotifier<String?>('Work');

  SavedAddress? get selectedAddress => selectedAddressNotifier.value;
  String? get currentAddress =>
      customLocationNotifier.value ?? selectedAddressNotifier.value?.label ?? addressNotifier.value;
  List<SavedAddress> get savedAddresses => savedAddressesNotifier.value;

  /// The active delivery label displayed on top header (e.g. "Work", "Home", or "House123")
  String get activeDeliveryLabel {
    if (customLocationNotifier.value != null && customLocationNotifier.value!.trim().isNotEmpty) {
      return customLocationNotifier.value!.trim();
    }
    return selectedAddressNotifier.value?.label ?? 'Work';
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
  }

  /// Legacy helper
  void setAddress(String address, {String label = 'Home'}) {
    addAddress(label: label, address: address, selectImmediately: true);
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
