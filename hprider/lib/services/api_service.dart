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

  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _currentUser;
  static Map<String, dynamic>? _currentRider;

  static String? get accessToken => _accessToken;
  static bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static Map<String, dynamic>? get currentRider => _currentRider;

  /// Restores a saved session from disk, if any.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('rider_access_token');
      _refreshToken = prefs.getString('rider_refresh_token');
      final userJson = prefs.getString('rider_user');
      if (userJson != null) {
        _currentUser = jsonDecode(userJson);
      }
    } catch (e) {
      debugPrint('ApiService.init error: $e');
    }
  }

  static Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString('rider_access_token', _accessToken!);
    if (_refreshToken != null) await prefs.setString('rider_refresh_token', _refreshToken!);
    if (_currentUser != null) await prefs.setString('rider_user', jsonEncode(_currentUser));
  }

  static Map<String, String> _headers({bool needsAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (needsAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // ─── AUTH ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final user = data['data']['user'];
        if ((user['role'] ?? '') != 'RIDER') {
          return {'success': false, 'message': 'This account is not a rider account.'};
        }
        _accessToken = data['data']['accessToken'];
        _refreshToken = data['data']['refreshToken'];
        _currentUser = user;
        await _persistSession();
      }
      return data;
    } catch (e) {
      debugPrint('API Error (login): $e');
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  static Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _headers(),
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _accessToken = data['data']['accessToken'];
        await _persistSession();
        return true;
      }
    } catch (e) {
      debugPrint('API Error (refresh): $e');
    }
    return false;
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _currentRider = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rider_access_token');
    await prefs.remove('rider_refresh_token');
    await prefs.remove('rider_user');
  }

  /// Wraps a request; on 401, attempts one token refresh and retries once.
  static Future<http.Response> _authedRequest(Future<http.Response> Function() request) async {
    var res = await request();
    if (res.statusCode == 401 && await _tryRefreshToken()) {
      res = await request();
    }
    return res;
  }

  // ─── RIDER STATUS & LOCATION ──────────────────────────────

  static Future<Map<String, dynamic>?> getMyRiderProfile() async {
    try {
      final res = await _authedRequest(() => http.get(
            Uri.parse('$baseUrl/riders/me'),
            headers: _headers(needsAuth: true),
          ).timeout(const Duration(seconds: 10)));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentRider = data['data'];
        return _currentRider;
      }
    } catch (e) {
      debugPrint('API Error (getMyRiderProfile): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateAvailability(String status) async {
    try {
      final res = await _authedRequest(() => http.patch(
            Uri.parse('$baseUrl/riders/status'),
            headers: _headers(needsAuth: true),
            body: jsonEncode({'status': status}),
          ).timeout(const Duration(seconds: 8)));
      final data = jsonDecode(res.body);
      if (data['success'] == true) _currentRider = data['data'];
      return data;
    } catch (e) {
      debugPrint('API Error (updateAvailability): $e');
      return {'success': false, 'message': 'Could not update availability.'};
    }
  }

  static Future<bool> pushLocation(double lat, double lng, {double? heading, double? speed}) async {
    try {
      final res = await _authedRequest(() => http.post(
            Uri.parse('$baseUrl/riders/location'),
            headers: _headers(needsAuth: true),
            body: jsonEncode({'latitude': lat, 'longitude': lng, if (heading != null) 'heading': heading, if (speed != null) 'speed': speed}),
          ).timeout(const Duration(seconds: 8)));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API Error (pushLocation): $e');
      return false;
    }
  }

  // ─── DELIVERIES ────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getActiveDelivery() async {
    try {
      final res = await _authedRequest(() => http.get(
            Uri.parse('$baseUrl/deliveries/me/active'),
            headers: _headers(needsAuth: true),
          ).timeout(const Duration(seconds: 10)));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('API Error (getActiveDelivery): $e');
    }
    return null;
  }

  static Future<List<dynamic>> getDeliveryHistory({int page = 1, int limit = 20}) async {
    try {
      final res = await _authedRequest(() => http.get(
            Uri.parse('$baseUrl/deliveries/me/history?page=$page&limit=$limit'),
            headers: _headers(needsAuth: true),
          ).timeout(const Duration(seconds: 10)));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['deliveries'] ?? [];
      }
    } catch (e) {
      debugPrint('API Error (getDeliveryHistory): $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> _deliveryAction(String deliveryId, String action, {Map<String, dynamic>? body}) async {
    try {
      final res = await _authedRequest(() => http.patch(
            Uri.parse('$baseUrl/deliveries/$deliveryId/$action'),
            headers: _headers(needsAuth: true),
            body: jsonEncode(body ?? {}),
          ).timeout(const Duration(seconds: 10)));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('API Error (delivery/$action): $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> acceptDelivery(String deliveryId) => _deliveryAction(deliveryId, 'accept');
  static Future<Map<String, dynamic>> markPickedUp(String deliveryId) => _deliveryAction(deliveryId, 'pickup');
  static Future<Map<String, dynamic>> markOutForDelivery(String deliveryId) => _deliveryAction(deliveryId, 'out-for-delivery');
  static Future<Map<String, dynamic>> markDelivered(String deliveryId) => _deliveryAction(deliveryId, 'delivered');
  static Future<Map<String, dynamic>> markFailed(String deliveryId, String reason) =>
      _deliveryAction(deliveryId, 'failed', body: {'reason': reason});
}
