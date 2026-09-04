import 'package:flutter/foundation.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final ValueNotifier<List<Map<String, dynamic>>> favoritesNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  List<Map<String, dynamic>> get items => favoritesNotifier.value;

  bool isFavorite(dynamic id) {
    if (id == null) return false;
    final targetId = id.toString();
    return favoritesNotifier.value.any((item) => item['id']?.toString() == targetId);
  }

  bool toggleFavorite(Map<String, dynamic> item) {
    final currentList = List<Map<String, dynamic>>.from(favoritesNotifier.value);
    final itemId = item['id']?.toString() ?? item['name']?.toString() ?? '';
    final index = currentList.indexWhere((it) => (it['id']?.toString() ?? it['name']?.toString()) == itemId);

    bool added = false;
    if (index >= 0) {
      currentList.removeAt(index);
      added = false;
    } else {
      currentList.add(Map<String, dynamic>.from(item));
      added = true;
    }

    favoritesNotifier.value = currentList;
    return added;
  }
}
