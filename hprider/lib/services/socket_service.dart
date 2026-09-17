import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'api_service.dart';

/// Thin singleton wrapper around a Socket.IO client connected to the
/// HungerPoint backend, used to receive real-time assignment
/// notifications and to broadcast the rider's live location.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  socket_io.Socket? _socket;

  socket_io.Socket get socket {
    if (_socket != null) return _socket!;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    _socket = socket_io.io(
      base,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': ApiService.accessToken ?? ''})
          .enableAutoConnect()
          .build(),
    );
    return _socket!;
  }

  /// Reconnects with the current access token — call after login, since the
  /// socket may have been created before a token existed.
  void reconnectWithAuth() {
    _socket?.dispose();
    _socket = null;
    socket.connect();
  }

  void sendLocation({required double lat, required double lng, String? orderId, double? heading, double? speed}) {
    socket.emit('rider:location', {
      'latitude': lat,
      'longitude': lng,
      if (orderId != null) 'orderId': orderId,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
