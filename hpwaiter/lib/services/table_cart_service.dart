import 'package:flutter/foundation.dart';

/// A waiter can be building up orders for several tables at once, so unlike
/// the customer app's single global cart, this keeps one draft cart per
/// table id.
class TableCartService {
  static final TableCartService _instance = TableCartService._internal();
  factory TableCartService() => _instance;
  TableCartService._internal();

  final Map<String, List<Map<String, dynamic>>> _cartsByTable = {};

  /// Bumped on every mutation so widgets listening via ValueListenableBuilder
  /// know to rebuild, regardless of which table changed.
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  List<Map<String, dynamic>> itemsFor(String tableId) =>
      List<Map<String, dynamic>>.from(_cartsByTable[tableId] ?? []);

  int totalItemCountFor(String tableId) =>
      itemsFor(tableId).fold(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));

  int totalPriceFor(String tableId) => itemsFor(tableId).fold(
        0,
        (sum, item) => sum + (((item['price'] as int?) ?? 0) * ((item['quantity'] as int?) ?? 1)),
      );

  void addItem(String tableId, Map<String, dynamic> newItem) {
    final currentList = itemsFor(tableId);
    final variation = newItem['variation'] ?? 'Regular';
    final name = newItem['name'];
    final flavour = newItem['flavour'] ?? '';
    final drink = newItem['drink'] ?? '';
    final toppings = (newItem['toppings'] as List?)
            ?.map((t) => t is Map ? (t['name'] ?? '') : t.toString())
            .join(',') ??
        '';

    final index = currentList.indexWhere((it) {
      final itToppings = (it['toppings'] as List?)
              ?.map((t) => t is Map ? (t['name'] ?? '') : t.toString())
              .join(',') ??
          '';
      return it['name'] == name &&
          (it['variation'] ?? 'Regular') == variation &&
          (it['flavour'] ?? '') == flavour &&
          (it['drink'] ?? '') == drink &&
          itToppings == toppings;
    });

    if (index >= 0) {
      final existing = Map<String, dynamic>.from(currentList[index]);
      existing['quantity'] = ((existing['quantity'] as int?) ?? 1) + ((newItem['quantity'] as int?) ?? 1);
      currentList[index] = existing;
    } else {
      currentList.add(Map<String, dynamic>.from(newItem));
    }

    _cartsByTable[tableId] = currentList;
    version.value++;
  }

  void updateQuantity(String tableId, int index, int newQuantity) {
    final currentList = itemsFor(tableId);
    if (index < 0 || index >= currentList.length) return;

    if (newQuantity <= 0) {
      currentList.removeAt(index);
    } else {
      final item = Map<String, dynamic>.from(currentList[index]);
      item['quantity'] = newQuantity;
      currentList[index] = item;
    }

    _cartsByTable[tableId] = currentList;
    version.value++;
  }

  void removeItem(String tableId, int index) {
    final currentList = itemsFor(tableId);
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      _cartsByTable[tableId] = currentList;
      version.value++;
    }
  }

  void clearTable(String tableId) {
    _cartsByTable.remove(tableId);
    version.value++;
  }
}
