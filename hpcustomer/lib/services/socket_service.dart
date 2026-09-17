import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'api_service.dart';

/// Thin singleton wrapper around a Socket.IO client connected to the
/// HungerPoint backend, used for live order tracking updates.
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

  void trackOrder(String orderId) {
    socket.emit('order:track', {'orderId': orderId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
