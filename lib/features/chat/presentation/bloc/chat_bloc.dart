import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart'; // Necesario para fold
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart'; 
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
// 🟢 AÑADIDO: Importación de la entidad ChatRoomType
import '../../domain/usecases/get_chat_rooms_stream.dart';
import '../../domain/usecases/get_messages_stream.dart'; // Para MessagesStreamParams
import '../../domain/usecases/mark_as_read.dart'; // Para MarkAsReadParams
import '../../domain/usecases/send_message.dart'; // Para SendParams


part 'chat_event.dart';
part 'chat_state.dart';

// ❌ ELIMINADA: Esta redefinición causaba el error de conflicto de tipos:
// class NoParams extends Equatable { const NoParams(); @override List<Object> get props => []; }

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

    // La clase NoParams utilizada aquí es la importada de '../../../core/usecases/usecase.dart'
    final roomsStream = getChatRoomsStream(NoParams()); 

    // Nos suscribimos al Stream que ya emite Either<Failure, List<ChatRoom>>
    _roomsSubscription = roomsStream.listen(
      (failureOrRooms) {
        // En cada emisión del Stream, usamos fold para manejar el éxito o el fallo
        failureOrRooms.fold(
          (failure) => emit(ChatError(failure.errorMessage)),
          (rooms) => add(ChatRoomsReceived(rooms)),
        );
      },
      // Manejar errores de la tubería del stream
      onError: (error, stackTrace) {
        emit(const ChatError('Error inesperado al escuchar salas de chat.'));
      }
    );
  }

  // 2. Maneja los datos de las salas recibidos del Stream
  void _onRoomsReceived(
    ChatRoomsReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatRoomsLoaded(rooms: event.rooms));
  }

  // 3. Maneja la selección de una sala
  Future<void> _onRoomSelected(
    ChatRoomSelected event,
    Emitter<ChatState> emit,
  ) async {
    // Si estamos en un estado de salas cargadas, encontramos la sala
    if (state is ChatRoomsLoaded) {
      final roomsState = state as ChatRoomsLoaded;
      
      final room = roomsState.rooms.firstWhere(
        (r) => r.id == event.roomId,
        // Usamos una implementación compatible con la entidad ChatRoom
        orElse: () => ChatRoom(id: event.roomId, type: ChatRoomType.general, title: 'Sala no encontrada', memberIds: const []),
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

    // Usamos el método 'call' del Use Case que devuelve el Stream directamente
    final messagesStream = getMessagesStream(MessagesStreamParams(roomId: event.roomId));

    // Nos suscribimos al Stream que ya emite Either<Failure, List<Message>>
    _messagesSubscription = messagesStream.listen(
      (failureOrMessages) {
        failureOrMessages.fold(
          (failure) => emit(ChatError(failure.errorMessage)),
          (messages) => add(ChatMessagesReceived(messages)),
        );
      },
      // Manejar errores de la tubería del stream
      onError: (error, stackTrace) {
        emit(const ChatError('Error inesperado al escuchar mensajes.'));
      }
    );
  }

  // 5. Maneja los datos de los mensajes recibidos del Stream
  void _onMessagesReceived(
    ChatMessagesReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatRoomSelectedState) {
      final currentState = state as ChatRoomSelectedState;
      // Actualizamos el estado de la sala con la nueva lista de mensajes
      emit(currentState.copyWith(messages: event.messages));

      // Re-marcar como leído cada vez que llegan nuevos mensajes
      add(ChatMarkAsRead(currentState.room.id));
    }
  }

  // 6. Maneja el envío de un mensaje
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
        senderName: 'Usuario Actual', // Asumimos un nombre de usuario temporal
      ),
    );

    // No actualizamos la lista de mensajes aquí, el Stream se encargará de eso
    failureOrVoid.fold(
      (failure) {
        emit(currentState.copyWith(isSending: false));
        // Enviar un mensaje de error al usuario
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
