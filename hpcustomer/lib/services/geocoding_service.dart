import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A single geocoding search/reverse-geocoding result.
class GeoResult {
  final double lat;
  final double lng;
  final String displayName;

  const GeoResult({required this.lat, required this.lng, required this.displayName});
}

/// Thin wrapper around OpenStreetMap's Nominatim geocoding API.
///
/// Nominatim is free and requires no API key, but its usage policy requires
/// a descriptive User-Agent and reasonable request rates (no bulk/rapid-fire
/// requests) — https://operations.osmfoundation.org/policies/nominatim/
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'HungerPointApp/1.0 (contact: support@hungerpoint.pk)',
  };

  /// Forward geocoding: turns a free-text search query into candidate locations.
  /// Biased towards Pakistan since that's where HungerPoint operates.
  static Future<List<GeoResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'countrycodes': 'pk',
        'limit': '8',
        'addressdetails': '0',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) {
          return GeoResult(
            lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
            lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
            displayName: item['display_name']?.toString() ?? query,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('GeocodingService.search error: $e');
    }
    return [];
  }

  /// Reverse geocoding: turns coordinates into a human-readable address.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'jsonv2',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['display_name']?.toString();
      }
    } catch (e) {
      debugPrint('GeocodingService.reverseGeocode error: $e');
    }
    return null;
  }
}
