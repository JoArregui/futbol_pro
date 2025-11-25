import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/send_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // Use Cases
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final MarkAsRead markAsRead;
  final GetChatRooms getChatRooms;

  // ID y Nombre del usuario actual
  final String currentUserId;
  final String currentUserName;

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.markAsRead,
    required this.getChatRooms,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(ChatInitial()) {
    on<ChatRoomsSubscriptionRequested>(_onRoomsFetchRequested);
    on<ChatRoomsReceived>(_onRoomsReceived);
    on<ChatRoomSelected>(_onRoomSelected);
    on<ChatMessagesSubscriptionRequested>(_onMessagesFetchRequested);
    on<ChatMessagesReceived>(_onMessagesReceived);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMarkAsRead>(_onMarkAsRead);
  }

  // ... (Manejadores _onRoomsFetchRequested y _onRoomsReceived sin cambios)
  // ==================================================
  // 1. Maneja la solicitud de carga de las salas de chat (ANTES STREAM)
  // ==================================================
  Future<void> _onRoomsFetchRequested(
    ChatRoomsSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatRoomsLoaded) return;

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

  // 7. _onMarkAsRead
  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await markAsRead(MarkAsReadParams(
      roomId: event.roomId,
      userId: currentUserId,
    ));
  }

  // 8. Limpieza
  @override
  Future<void> close() {
    // ❌ Eliminamos el "unnecessary override" si no hay lógica de cancelación.
    // Si la dejamos, el compilador puede emitir una advertencia, pero es funcional.
    return super.close();
  }
}
