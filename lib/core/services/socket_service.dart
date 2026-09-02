import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:futbol_pro/core/consts.dart';

class SocketService {
  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  void connect({required String userId}) {
    if (_socket != null && _socket!.connected) return;
    final base = AppConsts.baseUrl.replaceAll('/api/v1', '');
    _socket = io.io(base, io.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build());
    _socket!.onConnect((_) {
      _socket!.emit('join_user', userId);
    });
  }

  void joinRoom(String roomId) => _socket?.emit('join_room', roomId);
  void leaveRoom(String roomId) => _socket?.emit('leave_room', roomId);
  void sendTyping(String roomId, String userId, bool isTyping) => _socket?.emit('typing', {'roomId': roomId, 'userId': userId, 'isTyping': isTyping});

  void onNewMessage(void Function(Map<String, dynamic>) handler) {
    _socket?.on('new_message', (data) => handler(Map<String, dynamic>.from(data as Map)));
  }

  void onChatUpdated(void Function(Map<String, dynamic>) handler) {
    _socket?.on('chat_updated', (data) => handler(Map<String, dynamic>.from(data as Map)));
  }

  void onChatCreated(void Function(Map<String, dynamic>) handler) {
    _socket?.on('chat_created', (data) => handler(Map<String, dynamic>.from(data as Map)));
  }

  void onTyping(void Function(Map<String, dynamic>) handler) {
    _socket?.on('typing', (data) => handler(Map<String, dynamic>.from(data as Map)));
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
