import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/core/services/notification_service.dart';
import 'package:futbol_pro/core/services/socket_service.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/create_chat.dart';
import '../../domain/usecases/search_users.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final MarkAsRead markAsRead;
  final GetChatRooms getChatRooms;
  final CreateChat createChat;
  final SearchUsers searchUsers;
  final AuthRepository authRepository;
  final SocketService socketService;
  final NotificationService? notifications;
  Timer? _typingTimer;

  String get currentUserId => authRepository.getCurrentUserId();
  String get currentUserName => authRepository.getCurrentUserName();

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.markAsRead,
    required this.getChatRooms,
    required this.createChat,
    required this.searchUsers,
    required this.authRepository,
    required this.socketService,
    this.notifications,
  }) : super(ChatInitial()) {
    on<ChatRoomsSubscriptionRequested>(_onRoomsFetchRequested);
    on<ChatRoomsReceived>(_onRoomsReceived);
    on<ChatRoomSelected>(_onRoomSelected);
    on<ChatMessagesSubscriptionRequested>(_onMessagesFetchRequested);
    on<ChatMessagesReceived>(_onMessagesReceived);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatCreateRequested>(_onCreateChat);
    on<ChatSearchRequested>(_onSearch);
    on<ChatTypingChanged>(_onTypingChanged);
    on<ChatSocketMessageReceived>(_onSocketMessage);
    on<ChatSocketTypingReceived>(_onSocketTyping);
    _initSocket();
  }

  void _initSocket() {
    if (currentUserId.isEmpty) return;
    try {
      socketService.connect(userId: currentUserId);
    socketService.onNewMessage((data) {
        final roomId = data['roomId']?.toString() ?? '';
        final imageUrl = data['imageUrl']?.toString();
        final msg = Message(
          id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: data['senderId']?.toString() ?? '',
          senderName: data['senderName']?.toString() ?? '',
          text: data['text']?.toString() ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch((data['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
          status: MessageStatus.delivered,
          type: imageUrl != null ? MessageType.image : MessageType.text,
          imageUrl: imageUrl,
        );
        add(ChatSocketMessageReceived(message: msg, roomId: roomId));
      });
      socketService.onChatUpdated((_) => add(ChatRoomsSubscriptionRequested()));
      socketService.onChatCreated((_) => add(ChatRoomsSubscriptionRequested()));
      socketService.onTyping((data) => add(ChatSocketTypingReceived(roomId: data['roomId'].toString(), userId: data['userId'].toString(), isTyping: data['isTyping'] as bool)));
    } catch (_) {}
  }

  // ... (Manejadores _onRoomsFetchRequested y _onRoomsReceived sin cambios)
  // ==================================================
  // 1. Maneja la solicitud de carga de las salas de chat (ANTES STREAM)
  // ==================================================
  Future<void> _onRoomsFetchRequested(ChatRoomsSubscriptionRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    final failureOrRooms =
        await getChatRooms(UserIdParams(userId: currentUserId));

    failureOrRooms.fold(
      (failure) {
        emit(ChatError(failure.errorMessage));
      },
      (rooms) {
        emit(ChatRoomsLoaded(rooms: rooms));
      },
    );
  }

  // 2. Mantenemos el _onRoomsReceived solo si queremos mantener la arquitectura de eventos
  void _onRoomsReceived(
    ChatRoomsReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatRoomsLoaded(rooms: event.rooms));
  }

  // ==================================================
  // 3. Lógica de selección de sala y carga de mensajes
  // ==================================================
  Future<void> _onRoomSelected(
    ChatRoomSelected event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoading) {
      return;
    }

    if (state is ChatRoomSelectedState &&
        (state as ChatRoomSelectedState).room.id == event.roomId) {
      add(ChatMarkAsRead(event.roomId));
      return;
    }

    if (state is ChatRoomsLoaded) {
      final roomsState = state as ChatRoomsLoaded;

      final room = roomsState.rooms.firstWhere(
        (r) => r.id == event.roomId,
        orElse: () => ChatRoom(
          id: event.roomId,
          title: 'Sala no encontrada',
          memberIds: const [],
          // 🟢 CORRECCIÓN: Agregar 'type' si es un parámetro requerido
          // Asumiendo que existe un enum ChatRoomType con un valor por defecto.
          type: ChatRoomType.private,
        ),
      );

      if (room.title == 'Sala no encontrada') {
        emit(const ChatError(
            'Error: La sala de chat solicitada no existe o no se encontró.'));
        return;
      }

      emit(ChatRoomSelectedState(room: room));
      try { socketService.joinRoom(room.id); } catch (_) {}
      add(ChatMessagesSubscriptionRequested(event.roomId));
      add(ChatMarkAsRead(event.roomId));
    } else {
      emit(const ChatError('Error: Las salas de chat no se han cargado.'));
    }
  }

  // ... (Manejadores _onMessagesFetchRequested, _onMessagesReceived, _onMessageSent, _onMarkAsRead sin cambios)
  // ==================================================
  // 4. Maneja la solicitud de carga de mensajes (ANTES STREAM)
  // ==================================================
  Future<void> _onMessagesFetchRequested(
    ChatMessagesSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatRoomSelectedState) return;

    final currentState = state as ChatRoomSelectedState;

    if (currentState.room.id != event.roomId) return;

    final failureOrMessages =
        await getMessages(MessagesParams(roomId: event.roomId));

    failureOrMessages.fold(
      (failure) {
        emit(ChatError(failure.errorMessage));
      },
      (messages) {
        add(ChatMessagesReceived(messages.reversed.toList()));
      },
    );
  }

  // 5. Mantenemos _onMessagesReceived
  void _onMessagesReceived(
    ChatMessagesReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatRoomSelectedState) {
      final currentState = state as ChatRoomSelectedState;

      emit(currentState.copyWith(messages: event.messages));

      add(ChatMarkAsRead(currentState.room.id));
    }
  }

  // 6. _onMessageSent
  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatRoomSelectedState) return;
    final currentState = state as ChatRoomSelectedState;

    emit(currentState.copyWith(isSending: true));

    final failureOrVoid = await sendMessage(
      SendParams(
        roomId: event.roomId,
        senderId: currentUserId,
        content: event.content,
        senderName: currentUserName,
        imageUrl: event.imageUrl,
      ),
    );

    failureOrVoid.fold(
      (failure) {
        emit(ChatError('Fallo al enviar el mensaje: ${failure.errorMessage}'));
        emit(currentState.copyWith(isSending: false));
      },
      (_) {
        emit(currentState.copyWith(isSending: false));
        // 🚨 Recargar mensajes para ver el mensaje enviado (API REST)
        add(ChatMessagesSubscriptionRequested(event.roomId));
      },
    );
  }

  Future<void> _onMarkAsRead(ChatMarkAsRead event, Emitter<ChatState> emit) async {
    await markAsRead(MarkAsReadParams(roomId: event.roomId, userId: currentUserId));
  }

  Future<void> _onCreateChat(ChatCreateRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final res = await createChat(CreateChatParams(title: event.title, type: event.type, memberIds: event.memberIds));
    res.fold(
      (f) => emit(ChatError(f.message)),
      (room) {
        emit(ChatRoomsLoaded(rooms: [room]));
        add(ChatRoomsSubscriptionRequested());
        add(ChatRoomSelected(room.id));
      },
    );
  }

  Future<void> _onSearch(ChatSearchRequested event, Emitter<ChatState> emit) async {
    emit(const ChatSearchState(isSearching: true));
    final res = await searchUsers(SearchUsersParams(query: event.query, excludeUid: currentUserId));
    res.fold(
      (f) => emit(ChatError(f.message)),
      (users) => emit(ChatSearchState(users: users, isSearching: false)),
    );
  }

  void _onTypingChanged(ChatTypingChanged event, Emitter<ChatState> emit) {
    socketService.sendTyping(event.roomId, currentUserId, event.isTyping);
    if (event.isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () => add(ChatTypingChanged(roomId: event.roomId, isTyping: false)));
    }
  }

  void _onSocketMessage(ChatSocketMessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatRoomSelectedState && (state as ChatRoomSelectedState).room.id == event.roomId) {
      final cur = state as ChatRoomSelectedState;
      final exists = cur.messages.any((m) => m.id == event.message.id);
      if (!exists) emit(cur.copyWith(messages: [...cur.messages, event.message]));
    } else {
      // actualizar lista en background
      add(ChatRoomsSubscriptionRequested());
      // Aviso local si el mensaje es de otro y no estoy en esa sala.
      if (event.message.senderId != currentUserId) {
        final preview = event.message.imageUrl != null
            ? '📷 ${event.message.text.isNotEmpty ? event.message.text : 'Foto'}'
            : event.message.text;
        notifications?.showLocal(
          title: event.message.senderName.isNotEmpty
              ? event.message.senderName
              : 'Nuevo mensaje',
          body: preview.length > 120 ? '${preview.substring(0, 120)}…' : preview,
        );
      }
    }
  }

  void _onSocketTyping(ChatSocketTypingReceived event, Emitter<ChatState> emit) {
    if (state is ChatRoomSelectedState && (state as ChatRoomSelectedState).room.id == event.roomId && event.userId != currentUserId) {
      final cur = state as ChatRoomSelectedState;
      emit(cur.copyWith(isTyping: event.isTyping, typingUserId: event.isTyping ? event.userId : null));
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    socketService.dispose();
    return super.close();
  }
}
