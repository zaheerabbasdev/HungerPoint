import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1';

  static Future<List<dynamic>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/categories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchProducts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/products'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Error logging in: $e');
    }
    return null;
  }
}
