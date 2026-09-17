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
  static const Duration _requestTimeout = Duration(seconds: 12);

  /// Runs [request] and retries it once on timeout/network error, since
  /// mobile connections routinely have brief drop-outs that a single retry
  /// recovers from.
  static Future<T?> _withRetry<T>(Future<T> Function() request) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await request();
      } catch (e) {
        final isLastAttempt = attempt == 1;
        debugPrint('GeocodingService request ${isLastAttempt ? 'failed' : 'retrying after error'}: $e');
        if (isLastAttempt) return null;
      }
    }
    return null;
  }

  /// Forward geocoding: turns a free-text search query into candidate locations.
  /// Biased towards Pakistan since that's where HungerPoint operates.
  static Future<List<GeoResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await _withRetry(() async {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'countrycodes': 'pk',
        'limit': '8',
        'addressdetails': '0',
      });
      final res = await http.get(uri, headers: _headers).timeout(_requestTimeout);
      if (res.statusCode != 200) return <GeoResult>[];

      final List<dynamic> data = jsonDecode(res.body);
      return data.map((item) {
        return GeoResult(
          lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
          lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
          displayName: item['display_name']?.toString() ?? query,
        );
      }).toList();
    });

    return results ?? [];
  }

  /// Reverse geocoding: turns coordinates into a human-readable address.
  static Future<String?> reverseGeocode(double lat, double lng) {
    return _withRetry<String?>(() async {
      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'jsonv2',
      });
      final res = await http.get(uri, headers: _headers).timeout(_requestTimeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      return data['display_name']?.toString();
    });
  }
}
