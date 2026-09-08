import 'package:flutter/foundation.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ValueNotifier<List<Map<String, dynamic>>> cartNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  List<Map<String, dynamic>> get items => cartNotifier.value;

  int get totalItemCount {
    return cartNotifier.value.fold(
      0,
      (sum, item) => sum + ((item['quantity'] as int?) ?? 1),
    );
  }

  int get totalPrice {
    return cartNotifier.value.fold(
      0,
      (sum, item) => sum + (((item['price'] as int?) ?? 0) * ((item['quantity'] as int?) ?? 1)),
    );
  }

  void addItem(Map<String, dynamic> newItem) {
    final currentList = List<Map<String, dynamic>>.from(cartNotifier.value);
    final variation = newItem['variation'] ?? 'Regular';
    final name = newItem['name'];
    final flavour = newItem['flavour'] ?? '';
    final drink = newItem['drink'] ?? '';
    final toppings = (newItem['toppings'] as List?)
            ?.map((t) => t is Map ? (t['name'] ?? '') : t.toString())
            .join(',') ??
        '';

    final index = currentList.indexWhere(
      (it) {
        final itToppings = (it['toppings'] as List?)
                ?.map((t) => t is Map ? (t['name'] ?? '') : t.toString())
                .join(',') ??
            '';
        return it['name'] == name &&
            (it['variation'] ?? 'Regular') == variation &&
            (it['flavour'] ?? '') == flavour &&
            (it['drink'] ?? '') == drink &&
            itToppings == toppings;
      },
    );

    if (index >= 0) {
      final existing = Map<String, dynamic>.from(currentList[index]);
      existing['quantity'] = ((existing['quantity'] as int?) ?? 1) + ((newItem['quantity'] as int?) ?? 1);
      currentList[index] = existing;
    } else {
      currentList.add(Map<String, dynamic>.from(newItem));
    }

    cartNotifier.value = currentList;
  }

  void updateQuantity(int index, int newQuantity) {
    final currentList = List<Map<String, dynamic>>.from(cartNotifier.value);
    if (index < 0 || index >= currentList.length) return;

    if (newQuantity <= 0) {
      currentList.removeAt(index);
    } else {
      final item = Map<String, dynamic>.from(currentList[index]);
      item['quantity'] = newQuantity;
      currentList[index] = item;
    }

    cartNotifier.value = currentList;
  }

  void removeItem(int index) {
    final currentList = List<Map<String, dynamic>>.from(cartNotifier.value);
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      cartNotifier.value = currentList;
    }
  }

  void clearCart() {
    cartNotifier.value = [];
  }

  int getItemCount(dynamic id, [String? name]) {
    final idStr = id?.toString();
    int count = 0;
    for (final it in cartNotifier.value) {
      final itId = it['id']?.toString();
      final itName = it['name']?.toString();
      if ((idStr != null && itId == idStr) ||
          (name != null && itName == name) ||
          (idStr != null && itName == idStr)) {
        count += (it['quantity'] as int?) ?? 1;
      }
    }
    return count;
  }

  void incrementItem(dynamic id, [String? name]) {
    final idStr = id?.toString();
    final currentList = List<Map<String, dynamic>>.from(cartNotifier.value);
    final index = currentList.indexWhere((it) {
      final itId = it['id']?.toString();
      final itName = it['name']?.toString();
      return (idStr != null && itId == idStr) ||
          (name != null && itName == name) ||
          (idStr != null && itName == idStr);
    });

    if (index >= 0) {
      final existing = Map<String, dynamic>.from(currentList[index]);
      existing['quantity'] = ((existing['quantity'] as int?) ?? 1) + 1;
      currentList[index] = existing;
      cartNotifier.value = currentList;
    }
  }

  void decrementItem(dynamic id, [String? name]) {
    final idStr = id?.toString();
    final currentList = List<Map<String, dynamic>>.from(cartNotifier.value);
    final index = currentList.indexWhere((it) {
      final itId = it['id']?.toString();
      final itName = it['name']?.toString();
      return (idStr != null && itId == idStr) ||
          (name != null && itName == name) ||
          (idStr != null && itName == idStr);
    });

    if (index >= 0) {
      final existing = Map<String, dynamic>.from(currentList[index]);
      final currentQty = (existing['quantity'] as int?) ?? 1;
      if (currentQty <= 1) {
        currentList.removeAt(index);
      } else {
        existing['quantity'] = currentQty - 1;
        currentList[index] = existing;
      }
      cartNotifier.value = currentList;
    }
  }

  void clear() {
    cartNotifier.value = [];
  }
}
