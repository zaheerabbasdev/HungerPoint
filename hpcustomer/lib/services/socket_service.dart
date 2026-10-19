import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'api_service.dart';

/// Thin singleton wrapper around a Socket.IO client connected to the
/// HungerPoint backend, used for live order tracking updates.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  socket_io.Socket? _socket;
  String? _socketToken;

  // Orders being watched. The server forgets a socket's rooms when it
  // reconnects (app in background, network change), so they are re-joined on
  // every connect — otherwise live updates silently stopped after a drop.
  final Set<String> _tracked = {};

  socket_io.Socket get socket {
    // A socket opened for another login (or before signing in) can't follow
    // this customer's orders: the server checks ownership on order:track.
    if (_socket != null && _socketToken != ApiService.accessToken) {
      _socket!.dispose();
      _socket = null;
    }
    if (_socket != null) return _socket!;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    _socketToken = ApiService.accessToken;
    _socket = socket_io.io(
      base,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _socketToken ?? ''})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket!.onConnect((_) {
      for (final id in _tracked) {
        _socket?.emit('order:track', {'orderId': id});
      }
    });
    return _socket!;
  }

  void trackOrder(String orderId) {
    _tracked.add(orderId);
    final s = socket;
    if (s.connected) s.emit('order:track', {'orderId': orderId});
  }

  void untrackOrder(String orderId) => _tracked.remove(orderId);

  void disconnect() {
    _tracked.clear();
    _socket?.dispose();
    _socket = null;
    _socketToken = null;
  }
}
