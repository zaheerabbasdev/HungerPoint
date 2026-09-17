import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../services/geocoding_service.dart';

/// A real, interactive OpenStreetMap widget used for picking a delivery
/// location. Shows a fixed center pin ("pin drop" UX): the map pans
/// underneath a stationary pin, and on every pan the center is
/// reverse-geocoded into a human-readable address.
///
/// Also provides free-text search (forward geocoding via Nominatim) and a
/// "use my current location" button (via device GPS).
class InteractiveMapView extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  /// Called whenever the resolved center location changes (pan, search,
  /// GPS button), with the coordinates and best-effort address text.
  final void Function(double lat, double lng, String address) onLocationChanged;

  const InteractiveMapView({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onLocationChanged,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}

class _InteractiveMapViewState extends State<InteractiveMapView> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _reverseGeocodeDebounce;
  Timer? _searchDebounce;
  List<GeoResult> _searchResults = [];
  bool _showSuggestions = false;
  bool _resolvingAddress = false;
  bool _locatingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Resolve an initial human-readable address for the starting point.
    _reverseGeocode(widget.initialLat, widget.initialLng);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _resolvingAddress = true);
    final address = await GeocodingService.reverseGeocode(lat, lng);
    if (!mounted) return;
    setState(() => _resolvingAddress = false);
    widget.onLocationChanged(lat, lng, address ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}');
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      _reverseGeocodeDebounce?.cancel();
      _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 500), () {
        final center = _mapController.camera.center;
        _reverseGeocode(center.latitude, center.longitude);
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await GeocodingService.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _showSuggestions = results.isNotEmpty;
      });
    });
  }

  void _selectSearchResult(GeoResult result) {
    _searchFocusNode.unfocus();
    setState(() {
      _searchController.text = result.displayName;
      _searchResults = [];
      _showSuggestions = false;
    });
    _mapController.move(LatLng(result.lat, result.lng), 16);
    widget.onLocationChanged(result.lat, result.lng, result.displayName);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locatingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Please enable location services to use this feature.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage('Location permission permanently denied. Enable it from app settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      _showMessage('Could not get your current location.');
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── Real interactive map ─────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.initialLat, widget.initialLng),
            initialZoom: 15,
            onMapEvent: _onMapEvent,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hungerpoint.app',
              maxZoom: 19,
            ),
          ],
        ),

        // ─── Fixed center pin (pin-drop UX) ────────────────────
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                  ),
                  CustomPaint(size: const Size(12, 7), painter: _PinTrianglePainter()),
                ],
              ),
            ),
          ),
        ),

        // ─── Search bar + suggestions ──────────────────────────
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E1B4B), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search address...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _showSuggestions = false;
                              });
                            },
                            child: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_showSuggestions && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 240),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, i) => const Divider(height: 1, indent: 50, endIndent: 16, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, i) {
                      final r = _searchResults[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectSearchResult(r),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.location_on_outlined, color: AppColors.primaryOrange, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r.displayName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // ─── "Use my current location" button ──────────────────
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'use_current_location_fab',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _locatingGps ? null : _useCurrentLocation,
            child: _locatingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange)),
                  )
                : const Icon(Icons.my_location, color: AppColors.primaryOrange),
          ),
        ),

        // ─── Resolving-address indicator ───────────────────────
        if (_resolvingAddress)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
              ]),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange))),
                  SizedBox(width: 8),
                  Text('Locating address...', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PinTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryOrange;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
