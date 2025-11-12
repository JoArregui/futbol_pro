import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_chat_rooms_stream.dart';
import '../../domain/usecases/get_messages_stream.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/send_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // Use Cases
  final GetMessagesStream getMessagesStream;
  final SendMessage sendMessage;
  final MarkAsRead markAsRead;
  final GetChatRoomsStream getChatRoomsStream;

  // ID del usuario actual (Necesario para MarkAsRead y SendMessage)
  final String currentUserId;

  // Suscripciones
  StreamSubscription<Either<Failure, List<Message>>>? _messagesSubscription;
  StreamSubscription<Either<Failure, List<ChatRoom>>>? _roomsSubscription;

  ChatBloc({
    required this.getMessagesStream,
    required this.sendMessage,
    required this.markAsRead,
    required this.getChatRoomsStream,
    required this.currentUserId,
  }) : super(ChatInitial()) {
    on<ChatRoomsSubscriptionRequested>(_onRoomsSubscriptionRequested);
    on<ChatRoomsReceived>(_onRoomsReceived);
    on<ChatRoomSelected>(_onRoomSelected);
    on<ChatMessagesSubscriptionRequested>(_onMessagesSubscriptionRequested);
    on<ChatMessagesReceived>(_onMessagesReceived);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMarkAsRead>(_onMarkAsRead);
  }

  // 1. Maneja la solicitud de suscripción a las salas de chat
  Future<void> _onRoomsSubscriptionRequested(
    ChatRoomsSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Si ya existe una suscripción, la cancelamos primero
    await _roomsSubscription?.cancel();
    emit(ChatLoading());

    final roomsStream = getChatRoomsStream(NoParams());

    _roomsSubscription = roomsStream.listen((failureOrRooms) {
      failureOrRooms.fold(
        (failure) => emit(ChatError(failure.errorMessage)),
        (rooms) => add(ChatRoomsReceived(rooms)),
      );
    }, onError: (error, stackTrace) {
      emit(const ChatError('Error inesperado al escuchar salas de chat.'));
    });
  }

  void _onRoomsReceived(
    ChatRoomsReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatRoomsLoaded(rooms: event.rooms));
  }

  Future<void> _onRoomSelected(
    ChatRoomSelected event,
    Emitter<ChatState> emit,
  ) async {
    // Si estamos en un estado de salas cargadas, encontramos la sala
    if (state is ChatRoomsLoaded) {
      final roomsState = state as ChatRoomsLoaded;

      final room = roomsState.rooms.firstWhere(
        (r) => r.id == event.roomId,
        orElse: () => ChatRoom(
            id: event.roomId,
            type: ChatRoomType.general,
            title: 'Sala no encontrada',
            memberIds: const []),
      );

      emit(ChatRoomSelectedState(room: room));

      // Disparamos la solicitud para empezar a escuchar mensajes de esta sala
      add(ChatMessagesSubscriptionRequested(event.roomId));

      // Marcar como leído inmediatamente
      add(ChatMarkAsRead(event.roomId));
    }
  }

  // 4. Maneja la solicitud de suscripción a los mensajes de la sala
  Future<void> _onMessagesSubscriptionRequested(
    ChatMessagesSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Si ya existe una suscripción, la cancelamos
    await _messagesSubscription?.cancel();

    final messagesStream =
        getMessagesStream(MessagesStreamParams(roomId: event.roomId));

    _messagesSubscription = messagesStream.listen((failureOrMessages) {
      failureOrMessages.fold(
        (failure) => emit(ChatError(failure.errorMessage)),
        (messages) => add(ChatMessagesReceived(messages)),
      );
    }, onError: (error, stackTrace) {
      emit(const ChatError('Error inesperado al escuchar mensajes.'));
    });
  }

  void _onMessagesReceived(
    ChatMessagesReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatRoomSelectedState) {
      final currentState = state as ChatRoomSelectedState;
      // Actualizamos el estado de la sala con la nueva lista de mensajes
      emit(currentState.copyWith(messages: event.messages));

      add(ChatMarkAsRead(currentState.room.id));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatRoomSelectedState) return;
    final currentState = state as ChatRoomSelectedState;

    // Indicamos que estamos enviando
    emit(currentState.copyWith(isSending: true));

    final failureOrVoid = await sendMessage(
      SendParams(
        roomId: event.roomId,
        senderId: event.senderId,
        content: event.content,
        senderName: 'Usuario Actual',
      ),
    );

    failureOrVoid.fold(
      (failure) {
        emit(currentState.copyWith(isSending: false));
      },
      (_) {
        emit(currentState.copyWith(isSending: false));
      },
    );
  }

  // 7. Maneja la acción de marcar como leído
  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await markAsRead(MarkAsReadParams(
      roomId: event.roomId,
      userId: currentUserId,
    ));
  }

  // Limpieza: Cancelar las suscripciones
  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _roomsSubscription?.cancel();
    return super.close();
  }
}
