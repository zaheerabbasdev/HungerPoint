import 'package:flutter/foundation.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ValueNotifier<List<Map<String, dynamic>>> cartNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([
    {
      'id': '6',
      'name': 'Thin Crust Beef Pepperoni',
      'desc': 'A crispy thin crust topped with beef pepperoni, mozzarella cheese, and rich marinara sauce.',
      'variation': 'Regular',
      'price': 1480,
      'quantity': 1,
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': '8',
      'name': 'Oven Baked Wings',
      'desc': 'Fresh Oven baked wings served with Dip Sauce.',
      'variation': '6pcs',
      'price': 580,
      'quantity': 1,
      'image': 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=400&q=80',
    },
  ]);

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

    final index = currentList.indexWhere(
      (it) => it['name'] == name && (it['variation'] ?? 'Regular') == variation,
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

  void clear() {
    cartNotifier.value = [];
  }
}
