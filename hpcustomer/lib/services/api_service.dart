import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configurable base URL:
  // - Real physical phone on Wi-Fi: 10.252.184.234
  // - Android Emulator: 10.0.2.2
  // - Web / Desktop: localhost
  static String hostIp = '10.252.184.234';
  static int port = 5000;

  static String get baseUrl {
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

  // Auth tokens in memory and persistent in SharedPreferences
  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _currentUser;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  static bool get isLoggedIn => isAuthenticated;
  static Map<String, dynamic>? get currentUser => _currentUser;

  /// Loads saved authentication tokens and session from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('hp_access_token');
      _refreshToken = prefs.getString('hp_refresh_token');
      final userJson = prefs.getString('hp_current_user');
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = jsonDecode(userJson);
      }
      debugPrint('ApiService initialized: isAuthenticated=$isAuthenticated, user=${_currentUser?['name']}');
    } catch (e) {
      debugPrint('Error initializing ApiService prefs: $e');
    }
  }

  static void setAuthTokens({String? accessToken, String? refreshToken, Map<String, dynamic>? user}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    if (user != null) _currentUser = user;

    // Persist asynchronously
    SharedPreferences.getInstance().then((prefs) {
      if (_accessToken != null) {
        prefs.setString('hp_access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        prefs.setString('hp_refresh_token', _refreshToken!);
      }
      if (_currentUser != null) {
        prefs.setString('hp_current_user', jsonEncode(_currentUser));
      }
    }).catchError((e) {
      debugPrint('Error saving tokens to SharedPreferences: $e');
    });
  }

  static void clearAuth() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('hp_access_token');
      prefs.remove('hp_refresh_token');
      prefs.remove('hp_current_user');
    }).catchError((e) {
      debugPrint('Error clearing tokens from SharedPreferences: $e');
    });
  }

  static void logout() => clearAuth();

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

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: _headers(),
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Could not send OTP'};
    } catch (e) {
      debugPrint('API Error (sendOtp): $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'otp': otp}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final resData = data['data'];
        if (resData['accessToken'] != null) {
          setAuthTokens(
            accessToken: resData['accessToken'],
            refreshToken: resData['refreshToken'],
            user: resData['user'],
          );
        }
        return {'success': true, 'data': resData};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP code'};
    } catch (e) {
      debugPrint('API Error (verifyOtp): $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> completeProfile({
    required String phone,
    required String name,
    String? dateOfBirth,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'name': name,
      };
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (email != null) body['email'] = email;

      final res = await http.post(
        Uri.parse('$baseUrl/auth/complete-profile'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        final resData = data['data'];
        setAuthTokens(
          accessToken: resData['accessToken'],
          refreshToken: resData['refreshToken'],
          user: resData['user'],
        );
        return {'success': true, 'data': resData};
      }
      return {'success': false, 'message': data['message'] ?? 'Profile setup failed'};
    } catch (e) {
      debugPrint('API Error (completeProfile): $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        setAuthTokens(
          accessToken: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
          user: data['data']['user'],
        );
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      debugPrint('API Error (login): $e');
      return {'success': false, 'message': 'Network error. Please ensure backend is running.'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        'password': password,
      };
      if (email != null && email.isNotEmpty) body['email'] = email;

      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        setAuthTokens(
          accessToken: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
          user: data['data']['user'],
        );
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      debugPrint('API Error (register): $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('API Error (getMe): $e');
    }
    return null;
  }

  // ─── CUSTOMER PROFILE & ADDRESSES ────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/customers/profile'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('API Error (getCustomerProfile): $e');
    }
    return null;
  }

  static Future<bool> updateCustomerProfile({
    String? fullName,
    String? email,
    String? dateOfBirth,
    String? avatarEmoji,
    String? profileImagePath,
    Map<String, dynamic>? data,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (avatarEmoji != null) body['avatarEmoji'] = avatarEmoji;
      if (profileImagePath != null) body['profileImagePath'] = profileImagePath;
      if (data != null) body.addAll(data);

      final res = await http.put(
        Uri.parse('$baseUrl/customers/profile'),
        headers: _headers(needsAuth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API Error (updateCustomerProfile): $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAddresses() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/customers/addresses'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (getAddresses): $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addAddress(Map<String, dynamic> addressData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customers/addresses'),
        headers: _headers(needsAuth: true),
        body: jsonEncode(addressData),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('API Error (addAddress): $e');
    }
    return null;
  }

  static Future<bool> deleteAddress(String addressId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/customers/addresses/$addressId'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 6));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API Error (deleteAddress): $e');
      return false;
    }
  }

  // ─── BRANCHES ────────────────────────────────────────────────

  static Future<List<dynamic>> fetchBranches() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/branches'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchBranches): $e');
    }
    return [];
  }

  // ─── CATEGORIES & PRODUCTS ───────────────────────────────────

  static dynamic _normalizeProduct(dynamic p) {
    if (p is! Map) return p;
    final map = Map<String, dynamic>.from(p);
    if (map['basePrice'] != null) {
      if (map['basePrice'] is String) {
        map['basePrice'] = double.tryParse(map['basePrice'] as String) ?? 0.0;
      } else if (map['basePrice'] is num) {
        map['basePrice'] = (map['basePrice'] as num).toDouble();
      }
    }
    if (map['price'] != null) {
      if (map['price'] is String) {
        map['price'] = double.tryParse(map['price'] as String) ?? 0.0;
      } else if (map['price'] is num) {
        map['price'] = (map['price'] as num).toDouble();
      }
    }
    if (map['image'] != null) {
      map['image'] = resolveImageUrl(map['image']?.toString());
    }
    if (map['images'] is List) {
      map['images'] = (map['images'] as List)
          .map((img) => resolveImageUrl(img?.toString()))
          .toList();
    }
    return map;
  }

  static Future<List<dynamic>> fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List<dynamic>? ?? [];
        return list.map((cat) {
          if (cat is Map) {
            final catMap = Map<String, dynamic>.from(cat);
            if (catMap['image'] != null) {
              catMap['image'] = resolveImageUrl(catMap['image']?.toString());
            }
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

  static Future<List<dynamic>> fetchProducts({String? categoryId, String? search}) async {
    try {
      var url = '$baseUrl/products';
      final params = <String>[];
      if (categoryId != null && categoryId.isNotEmpty) params.add('categoryId=$categoryId');
      if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final res = await http.get(
        Uri.parse(url),
        headers: _headers(),
      ).timeout(const Duration(seconds: 6));

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
      final res = await http.get(
        Uri.parse('$baseUrl/products/addons/all'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 6));

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

  static Future<Map<String, dynamic>> createOrder({
    required String branchId,
    required String type,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? deliveryAddress,
    String? notes,
    String? couponCode,
    Map<String, dynamic>? rawPayload,
  }) async {
    try {
      final body = rawPayload ?? <String, dynamic>{
        'branchId': branchId,
        'type': type,
        'items': items,
        'paymentMethod': paymentMethod,
      };
      if (rawPayload == null) {
        if (deliveryAddress != null) body['deliveryAddress'] = deliveryAddress;
        if (notes != null) body['notes'] = notes;
        if (couponCode != null) body['couponCode'] = couponCode;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers(needsAuth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to create order'};
    } catch (e) {
      debugPrint('API Error (createOrder): $e');
      return {'success': false, 'message': 'Network error while placing order'};
    }
  }

  static Future<List<dynamic>> getMyOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _headers(needsAuth: true),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (getMyOrders): $e');
    }
    return [];
  }

  // ─── COUPONS / VOUCHERS ──────────────────────────────────────

  static Future<List<dynamic>> fetchCoupons() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/coupons'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchCoupons): $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required num orderAmount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/coupons/validate'),
        headers: _headers(),
        body: jsonEncode({'code': code, 'amount': orderAmount}),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      debugPrint('API Error (validateCoupon): $e');
      return {'success': false, 'valid': false, 'message': 'Could not validate voucher', 'discount': 0};
    }
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────

  static Future<List<dynamic>> fetchNotifications() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers(needsAuth: isAuthenticated),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (fetchNotifications): $e');
    }
    return [];
  }

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: _headers(needsAuth: isAuthenticated),
      ).timeout(const Duration(seconds: 6));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API Error (markAllNotificationsAsRead): $e');
      return false;
    }
  }

  // ─── REVIEWS / FEEDBACK ──────────────────────────────────────

  static Future<bool> submitReview({
    required int rating,
    required String comment,
    String? productId,
  }) async {
    try {
      final body = <String, dynamic>{
        'rating': rating,
        'comment': comment,
      };
      if (productId != null) body['productId'] = productId;

      final res = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: _headers(needsAuth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('API Error (submitReview): $e');
      return false;
    }
  }
}
