import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:futbol_pro/core/consts.dart';

class SocketService {
  io.Socket? _socket;
  String? _userId;
  String? _token;
  String? _currentRoomId;

  void Function(Map<String, dynamic>)? _newMessageHandler;
  void Function(Map<String, dynamic>)? _chatUpdatedHandler;
  void Function(Map<String, dynamic>)? _chatCreatedHandler;
  void Function(Map<String, dynamic>)? _typingHandler;
  final Map<String, void Function(Map<String, dynamic>)> _appEventHandlers = {};

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String userId, String? token}) {
    // El servidor acepta el handshake sin JWT, pero no permite entrar en
    // ninguna sala. Evitamos dejar una conexión anónima como válida.
    final cleanToken = token?.trim() ?? '';
    if (userId.isEmpty || cleanToken.isEmpty) return;
    if (_socket != null &&
        _socket!.connected &&
        _userId == userId &&
        _token == cleanToken) {
      _bindAllHandlers();
      _joinPresence();
      return;
    }
    disconnect(keepSession: true);
    _userId = userId;
    _token = cleanToken;
    final base = AppConsts.effectiveBaseUrl.replaceAll('/api/v1', '');
    _socket = io.io(
      base,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .setAuth({'token': cleanToken})
          .build(),
    );
    _socket!.onConnect((_) {
      _joinPresence();
      _bindAllHandlers();
    });
    _socket!.on('reconnect', (_) {
      _joinPresence();
      _bindAllHandlers();
    });
    _bindAllHandlers();
  }

  void _joinPresence() {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    _socket?.emit('join_user', uid);
    final roomId = _currentRoomId;
    if (roomId != null && roomId.isNotEmpty) {
      _socket?.emit('join_room', roomId);
    }
  }

  void joinRoom(String roomId) {
    if (_currentRoomId != null &&
        _currentRoomId != roomId &&
        _currentRoomId!.isNotEmpty) {
      _socket?.emit('leave_room', _currentRoomId);
    }
    _currentRoomId = roomId;
    _socket?.emit('join_room', roomId);
  }

  void leaveRoom(String roomId) {
    if (_currentRoomId == roomId) _currentRoomId = null;
    _socket?.emit('leave_room', roomId);
  }

  void sendTyping(String roomId, String userId, bool isTyping) => _socket?.emit(
    'typing',
    {'roomId': roomId, 'userId': userId, 'isTyping': isTyping},
  );

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  void _safeOn(String event, void Function(Map<String, dynamic>)? handler) {
    _socket?.off(event);
    if (handler == null) return;
    _socket?.on(event, (data) {
      final map = _asMap(data);
      if (map != null) handler(map);
    });
  }

  void _bindAllHandlers() {
    _safeOn('new_message', _newMessageHandler);
    _safeOn('chat_updated', _chatUpdatedHandler);
    _safeOn('chat_created', _chatCreatedHandler);
    _safeOn('typing', _typingHandler);
    for (final entry in _appEventHandlers.entries) {
      _socket?.off(entry.key);
      _socket?.on(entry.key, (data) {
        final map = _asMap(data);
        entry.value(map ?? {'raw': data.toString()});
      });
    }
  }

  void onNewMessage(void Function(Map<String, dynamic>) handler) {
    _newMessageHandler = handler;
    _safeOn('new_message', handler);
  }

  void onChatUpdated(void Function(Map<String, dynamic>) handler) {
    _chatUpdatedHandler = handler;
    _safeOn('chat_updated', handler);
  }

  void onChatCreated(void Function(Map<String, dynamic>) handler) {
    _chatCreatedHandler = handler;
    _safeOn('chat_created', handler);
  }

  void onTyping(void Function(Map<String, dynamic>) handler) {
    _typingHandler = handler;
    _safeOn('typing', handler);
  }

  /// Eventos deportivos push (ver server/services/notify.js):
  /// match_created, match_updated, match_result, booking(_created), squad.
  void onAppEvent(String event, void Function(Map<String, dynamic>) handler) {
    _appEventHandlers[event] = handler;
    _socket?.off(event);
    _socket?.on(event, (data) {
      final map = _asMap(data);
      handler(map ?? {'raw': data.toString()});
    });
  }

  void disconnect({bool keepSession = false}) {
    try {
      _socket?.clearListeners();
      _socket?.disconnect();
    } catch (_) {}
    _socket?.dispose();
    _socket = null;
    if (!keepSession) {
      _userId = null;
      _token = null;
      _currentRoomId = null;
    }
  }

  /// Compat: antes los Blocs llamaban dispose() del singleton y lo mataban
  /// para toda la app. Ahora dispose() no destruye la conexión compartida;
  /// usad disconnect() explícito en logout.
  void dispose() {}

  void disposeForce() => disconnect();
}
