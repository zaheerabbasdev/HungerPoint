import 'package:flutter/foundation.dart';
import 'api_service.dart';

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

  int _parsePrice(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    if (raw is String) return double.tryParse(raw)?.toInt() ?? 0;
    return 0;
  }

  /// Fetches the customer's favorites from the backend and populates local state.
  Future<void> syncWithBackend() async {
    if (!ApiService.isLoggedIn) return;
    try {
      final products = await ApiService.getFavorites();
      favoritesNotifier.value = products.map<Map<String, dynamic>>((p) {
        return {
          'id': p['id']?.toString() ?? '',
          'name': p['name']?.toString() ?? 'Product',
          'desc': p['description']?.toString() ?? '',
          'price': _parsePrice(p['basePrice'] ?? p['price']),
          'image': p['image']?.toString(),
          'category': p['category']?['name']?.toString(),
          'variants': p['variants'],
          'addons': p['addons'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error syncing favorites with backend: $e');
    }
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

    // Fire-and-forget backend sync; local state is the source of truth for the UI.
    if (ApiService.isLoggedIn && itemId.isNotEmpty) {
      if (added) {
        ApiService.addFavorite(itemId);
      } else {
        ApiService.removeFavorite(itemId);
      }
    }

    return added;
  }

  void clear() {
    favoritesNotifier.value = [];
  }
}
