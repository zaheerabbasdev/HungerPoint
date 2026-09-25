import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configurable base URL — override at build/run time without editing
  // source, e.g.:
  //   flutter run --dart-define=API_HOST=192.168.1.50
  //   flutter build apk --dart-define=API_BASE_URL=https://api.hungerpoint.pk/api/v1
  //
  // The defaults below are for local development only:
  // - Real physical phone on Wi-Fi: this machine's LAN IP
  // - Android Emulator: 10.0.2.2
  // - Web / Desktop: localhost
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String hostIp = String.fromEnvironment('API_HOST', defaultValue: '10.252.184.234');
  static const int port = int.fromEnvironment('API_PORT', defaultValue: 5000);

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) {
      return 'http://localhost:$port/api/v1';
    }
    return 'http://$hostIp:$port/api/v1';
  }

  /// Resolves image URLs for local backend uploads on mobile devices
  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80';
    }
    String cleaned = url.trim().replaceAll(r'\', '/');
    if (cleaned.startsWith('/uploads/') || cleaned.startsWith('uploads/')) {
      final path = cleaned.startsWith('/') ? cleaned : '/$cleaned';
      return 'http://$hostIp:$port$path';
    }
    if (cleaned.contains('localhost:5000')) {
      return cleaned.replaceAll('localhost:5000', '$hostIp:$port');
    }
    if (cleaned.contains('127.0.0.1:5000')) {
      return cleaned.replaceAll('127.0.0.1:5000', '$hostIp:$port');
    }
    if (cleaned.contains('localhost:')) {
      return cleaned.replaceAll(RegExp(r'localhost:\d+'), '$hostIp:$port');
    }
    if (cleaned.contains('127.0.0.1:')) {
      return cleaned.replaceAll(RegExp(r'127\.0\.0\.1:\d+'), '$hostIp:$port');
    }
    return cleaned;
  }

  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _currentUser;

  static String? get accessToken => _accessToken;
  static bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  static Map<String, dynamic>? get currentUser => _currentUser;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('hpw_access_token');
      _refreshToken = prefs.getString('hpw_refresh_token');
      final userJson = prefs.getString('hpw_current_user');
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = jsonDecode(userJson);
      }
    } catch (e) {
      debugPrint('Error initializing ApiService prefs: $e');
    }
  }

  static void _setAuthTokens({String? accessToken, String? refreshToken, Map<String, dynamic>? user}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    if (user != null) _currentUser = user;

    SharedPreferences.getInstance().then((prefs) {
      if (_accessToken != null) prefs.setString('hpw_access_token', _accessToken!);
      if (_refreshToken != null) prefs.setString('hpw_refresh_token', _refreshToken!);
      if (_currentUser != null) prefs.setString('hpw_current_user', jsonEncode(_currentUser));
    }).catchError((e) {
      debugPrint('Error saving tokens to SharedPreferences: $e');
    });
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hpw_access_token');
    await prefs.remove('hpw_refresh_token');
    await prefs.remove('hpw_current_user');
  }

  static Map<String, String> _headers({bool needsAuth = false}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _accessToken != null) {
      map['Authorization'] = 'Bearer $_accessToken';
    }
    return map;
  }

  // ─── AUTHENTICATION ──────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final user = data['data']['user'];
        if (user?['role'] != 'WAITER') {
          return {'success': false, 'message': 'This account is not a waiter account.'};
        }
        _setAuthTokens(
          accessToken: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
          user: user,
        );
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      debugPrint('API Error (login): $e');
      return {'success': false, 'message': 'Network error. Please ensure backend is running.'};
    }
  }

  // ─── BRANCHES ────────────────────────────────────────────────

  static Future<List<dynamic>> fetchBranches() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/branches'), headers: _headers()).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchBranches): $e');
    }
    return [];
  }

  // ─── TABLES ──────────────────────────────────────────────────

  static Future<List<dynamic>> fetchTables({String? floor}) async {
    try {
      var url = '$baseUrl/tables';
      if (floor != null && floor.isNotEmpty) url += '?floor=${Uri.encodeComponent(floor)}';

      final res = await http.get(
        Uri.parse(url),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchTables): $e');
    }
    return [];
  }

  static Future<List<String>> fetchFloors() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tables/floors'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List<dynamic>? ?? []).map((f) => f.toString()).toList();
      }
    } catch (e) {
      debugPrint('API Error (fetchFloors): $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchTableById(String tableId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tables/$tableId'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('API Error (fetchTableById): $e');
    }
    return null;
  }

  // ─── CATEGORIES & PRODUCTS ───────────────────────────────────

  static dynamic _normalizeProduct(dynamic p) {
    if (p is! Map) return p;
    final map = Map<String, dynamic>.from(p);
    if (map['basePrice'] != null) {
      map['basePrice'] = map['basePrice'] is String
          ? (double.tryParse(map['basePrice']) ?? 0.0)
          : (map['basePrice'] as num).toDouble();
    }
    if (map['image'] != null) {
      map['image'] = resolveImageUrl(map['image']?.toString());
    }
    return map;
  }

  static Future<List<dynamic>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers()).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List<dynamic>? ?? [];
        return list.map((cat) {
          if (cat is Map) {
            final catMap = Map<String, dynamic>.from(cat);
            if (catMap['image'] != null) catMap['image'] = resolveImageUrl(catMap['image']?.toString());
            if (catMap['products'] is List) {
              catMap['products'] = (catMap['products'] as List).map(_normalizeProduct).toList();
            }
            return catMap;
          }
          return cat;
        }).toList();
      }
    } catch (e) {
      debugPrint('API Error (fetchCategories): $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchProducts({String? categoryId}) async {
    try {
      var url = '$baseUrl/products';
      if (categoryId != null && categoryId.isNotEmpty) url += '?categoryId=$categoryId';

      final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List<dynamic>? ?? [];
        return list.map(_normalizeProduct).toList();
      }
    } catch (e) {
      debugPrint('API Error (fetchProducts): $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchAddons() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/products/addons/all'), headers: _headers()).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchAddons): $e');
    }
    return [];
  }

  // ─── ORDERS ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createDineInOrder({
    required String branchId,
    required String tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({
          'branchId': branchId,
          'tableId': tableId,
          'type': 'DINE_IN',
          'source': 'WAITER_APP',
          'paymentMethod': 'POS_CASH',
          'items': items,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to place order'};
    } catch (e) {
      debugPrint('API Error (createDineInOrder): $e');
      return {'success': false, 'message': 'Network error while placing order'};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update order'};
    } catch (e) {
      debugPrint('API Error (updateOrderStatus): $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('API Error (getOrderById): $e');
    }
    return null;
  }

  static Future<List<dynamic>> getMyBranchOrders({String? type, String? status}) async {
    try {
      final params = <String>[];
      if (type != null) params.add('type=$type');
      if (status != null) params.add('status=$status');
      var url = '$baseUrl/orders';
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final res = await http.get(Uri.parse(url), headers: _headers(needsAuth: true)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['orders'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (getMyBranchOrders): $e');
    }
    return [];
  }

  // ─── RESERVATIONS ────────────────────────────────────────────

  static Future<List<dynamic>> fetchReservations({String? status}) async {
    try {
      var url = '$baseUrl/reservations';
      if (status != null) url += '?status=$status';

      final res = await http.get(Uri.parse(url), headers: _headers(needsAuth: true)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchReservations): $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createReservation({
    required String tableId,
    required String branchId,
    required String guestName,
    required String guestPhone,
    required int partySize,
    required DateTime reservedFor,
    String? notes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reservations'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({
          'tableId': tableId,
          'branchId': branchId,
          'guestName': guestName,
          'guestPhone': guestPhone,
          'partySize': partySize,
          'reservedFor': reservedFor.toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to reserve table'};
    } catch (e) {
      debugPrint('API Error (createReservation): $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> seatReservation(String reservationId) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/reservations/$reservationId/seat'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message'] ?? 'Failed to seat guests'};
    } catch (e) {
      debugPrint('API Error (seatReservation): $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> cancelReservation(String reservationId, {bool noShow = false}) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/reservations/$reservationId/cancel'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({'noShow': noShow}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message'] ?? 'Failed to cancel reservation'};
    } catch (e) {
      debugPrint('API Error (cancelReservation): $e');
      return {'success': false, 'message': 'Network error'};
    }
  }
}
