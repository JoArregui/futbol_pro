import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:futbol_pro/core/consts.dart';

class SocketService {
  io.Socket? _socket;
  String? _userId;
  bool get isConnected => _socket?.connected ?? false;

  void connect({required String userId, String? token}) {
    if (userId.isEmpty) return;
    // Re-join si cambia de usuario; evita listeners duplicados.
    if (_socket != null && _socket!.connected && _userId == userId) return;
    disconnect();
    _userId = userId;
    final base = AppConsts.effectiveBaseUrl.replaceAll('/api/v1', '');
    _socket = io.io(
      base,
      io.OptionBuilder().setTransports(['websocket']).enableAutoConnect()
      // El JWT viaja como auth para que el servidor verifique join_user.
      .setAuth({'token': token ?? ''}).build(),
    );
    _socket!.onConnect((_) {
      _socket!.emit('join_user', userId);
    });
  }

  void joinRoom(String roomId) => _socket?.emit('join_room', roomId);
  void leaveRoom(String roomId) => _socket?.emit('leave_room', roomId);
  void sendTyping(String roomId, String userId, bool isTyping) => _socket?.emit(
    'typing',
    {'roomId': roomId, 'userId': userId, 'isTyping': isTyping},
  );

  void _safeOn(String event, void Function(Map<String, dynamic>) handler) {
    _socket?.off(event);
    _socket?.on(event, (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  void onNewMessage(void Function(Map<String, dynamic>) handler) {
    _safeOn('new_message', handler);
  }

  void onChatUpdated(void Function(Map<String, dynamic>) handler) {
    _safeOn('chat_updated', handler);
  }

  void onChatCreated(void Function(Map<String, dynamic>) handler) {
    _safeOn('chat_created', handler);
  }

  void onTyping(void Function(Map<String, dynamic>) handler) {
    _safeOn('typing', handler);
  }

  /// Eventos deportivos push (ver server/services/notify.js):
  /// match_created, match_updated, match_result, booking(_created), squad.
  void onAppEvent(String event, void Function(Map<String, dynamic>) handler) {
    _socket?.on(event, (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      } else {
        handler({'raw': data.toString()});
      }
    });
  }

  void disconnect() {
    try {
      _socket?.clearListeners();
      _socket?.disconnect();
    } catch (_) {}
    _socket?.dispose();
    _socket = null;
  }

  /// Compat: antes los Blocs llamaban dispose() del singleton y lo mataban
  /// para toda la app. Ahora dispose() no destruye la conexión compartida;
  /// usad disconnect() explícito en logout.
  void dispose() {}

  void disposeForce() => disconnect();
}
