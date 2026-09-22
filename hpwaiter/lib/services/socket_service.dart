import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'api_service.dart';

/// Thin singleton wrapper around a Socket.IO client connected to the
/// HungerPoint backend, used to receive real-time order status updates
/// (kitchen preparing/ready) for the waiter's branch.
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

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
