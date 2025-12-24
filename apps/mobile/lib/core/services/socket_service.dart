import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Base URL should be configured properly (e.g. from environment)
  // Hardcoded for Android Emulator as per existing code
  static const String _baseUrl = 'http://10.0.2.2:3000/chat';

  bool get isConnected => _socket?.connected ?? false;
  IO.Socket? get socket => _socket;

  void connect(String token) {
    if (_socket != null) {
      if (_socket!.connected) return;
      // Update token if needed? For now, disconnect and reconnect if token changed is safer
      _socket!.dispose();
    }

    debugPrint('[SocketService] Connecting to $_baseUrl...');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected');
    });

    _socket!.onConnectError((data) {
      debugPrint('[SocketService] Connect Error: $data');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void joinRoom(String room) {
    // Implement if needed for specific rooms, though backend joins handleConnection
  }
}
