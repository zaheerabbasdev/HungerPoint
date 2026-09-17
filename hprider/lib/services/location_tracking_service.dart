import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'socket_service.dart';

/// Streams the rider's GPS position while tracking is active:
/// - broadcasts every update over Socket.IO for live customer tracking
/// - periodically persists a snapshot to the backend for delivery history
///
/// Per the spec, riders should NOT be tracked while offline — callers must
/// only [start] this while the rider is ONLINE or on an active delivery, and
/// [stop] it as soon as neither is true.
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionSub;
  Timer? _persistTimer;
  String? _activeOrderId;
  bool get isTracking => _positionSub != null;

  /// Requests location permission if needed. Returns true if granted.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Sets (or clears) which order's tracking room location updates should be
  /// attributed to, without restarting the underlying GPS stream.
  void setActiveOrder(String? orderId) {
    _activeOrderId = orderId;
  }

  Future<void> start({String? orderId}) async {
    _activeOrderId = orderId;
    if (isTracking) return;

    final granted = await ensurePermission();
    if (!granted) {
      debugPrint('LocationTrackingService: permission not granted, cannot start tracking.');
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
    ).listen((position) {
      SocketService().sendLocation(
        lat: position.latitude,
        lng: position.longitude,
        orderId: _activeOrderId,
        heading: position.heading,
        speed: position.speed,
      );
    });

    // Persist a snapshot every 30s (independent of the higher-frequency socket stream).
    _persistTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await ApiService.pushLocation(position.latitude, position.longitude, heading: position.heading, speed: position.speed);
      } catch (e) {
        debugPrint('LocationTrackingService: failed to persist location: $e');
      }
    });
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _persistTimer?.cancel();
    _persistTimer = null;
    _activeOrderId = null;
  }
}
