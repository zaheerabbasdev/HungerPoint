import 'package:flutter/foundation.dart';

/// Simple in-memory service to store the user's selected delivery address.
/// Widgets can listen to [addressNotifier] to react to changes.
class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final ValueNotifier<String?> addressNotifier = ValueNotifier<String?>(null);

  String? get currentAddress => addressNotifier.value;

  void setAddress(String address) {
    addressNotifier.value = address;
  }

  void clearAddress() {
    addressNotifier.value = null;
  }
}
