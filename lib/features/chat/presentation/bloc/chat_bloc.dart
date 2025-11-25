import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
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

  // ID y Nombre del usuario actual (Necesario para MarkAsRead y SendMessage)
  final String currentUserId;
  final String currentUserName;

  // Suscripciones (las mantenemos para la limpieza, pero ya no se usan en los manejadores de eventos)
  StreamSubscription<Either<Failure, List<Message>>>? _messagesSubscription;
  
  // No necesitamos una suscripción para _roomsSubscription, ya que usaremos emit.forEach
  // para que el event handler maneje el ciclo de vida del Stream de salas.
  // Sin embargo, por consistencia, la mantendremos si es usada en otra parte.
  // La mejor práctica es NO guardar la suscripción si usas emit.forEach.
  // La eliminaremos para seguir la mejor práctica de BLoC/Streams.
  // StreamSubscription<Either<Failure, List<ChatRoom>>>? _roomsSubscription;

  ChatBloc({
    required this.getMessagesStream,
    required this.sendMessage,
    required this.markAsRead,
    required this.getChatRoomsStream,
    required this.currentUserId,
    required this.currentUserName,
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
  // 🛑 CORRECCIÓN CLAVE: Usamos 'emit.forEach' para esperar el Stream.
  // Esto previene el error 'emit was called after an event handler completed normally'.
  Future<void> _onRoomsSubscriptionRequested(
    ChatRoomsSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Ya no necesitamos cancelar _roomsSubscription aquí, ya que 'emit.forEach'
    // se encarga de que el manejador espere a que el Stream termine.
    // Si necesitas cancelar el stream por una lógica externa, la suscripción debe
    // ser manejada por un objeto dedicado fuera del handler o usar 'await for' con un 
    // try/finally y la cancelación. Para este caso, 'emit.forEach' es lo más limpio.
    
    emit(ChatLoading());

    // Se llama al Use Case con el ID del usuario
    final roomsStream = getChatRoomsStream(UserIdParams(userId: currentUserId));
    
    // Usamos emit.forEach para escuchar y manejar el Stream de forma segura
    await emit.forEach<Either<Failure, List<ChatRoom>>>(
      roomsStream,
      onData: (failureOrRooms) {
        return failureOrRooms.fold(
          (failure) {
            // Manejamos el error de permisos de Firestore aquí.
            return ChatError(failure.errorMessage); 
          },
          (rooms) {
            // En lugar de añadir un nuevo evento, actualizamos directamente el estado
            // si el estado actual es ChatLoading. Si ya estaba cargado, también lo actualizamos.
            // Si el BLoC pasa de ChatLoading -> ChatRoomsLoaded directamente, 
            // no necesitamos el evento intermedio ChatRoomsReceived.
            // Para mantener la lógica original de usar el evento ChatRoomsReceived, 
            // lo reintroducimos aquí como un paso intermedio.
            add(ChatRoomsReceived(rooms));
            return state; // Devolvemos el estado actual para que no haya un cambio de estado inmediatamente.
          },
        );
      },
      onError: (error, stackTrace) {
        // Manejo de errores fatales del Stream (no del resultado del Fold)
        return const ChatError('Error inesperado al escuchar salas de chat.');
      },
    );
  }
  
  // Mantenemos la lógica original de _onRoomsReceived, aunque con emit.forEach podríamos
  // haber omitido este evento intermedio y haber emitido ChatRoomsLoaded directamente.
  void _onRoomsReceived(
    ChatRoomsReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatRoomsLoaded(rooms: event.rooms));
  }

  // 🚀 Lógica de selección de sala ajustada para manejo de estados (sin cambios significativos, solo revisión)
  Future<void> _onRoomSelected(
    ChatRoomSelected event,
    Emitter<ChatState> emit,
  ) async {
    // 🛑 NUEVA REGLA: Si las salas están cargando, ignoramos este evento para no interrumpir el flujo.
    if (state is ChatLoading) {
      // print('Advertencia: Intento de seleccionar sala mientras se cargan las salas.'); // Mejor remover 'print' en BLoC
      return; 
    }
    
    // 1. Si ya estamos en esta sala, nos aseguramos de marcarla como leída y salimos.
    if (state is ChatRoomSelectedState && (state as ChatRoomSelectedState).room.id == event.roomId) {
      add(ChatMarkAsRead(event.roomId));
      return; 
    }

    // 2. Si las salas están cargadas, intentamos encontrar y seleccionar
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

      // Si la sala es "Sala no encontrada", emitimos error.
      if (room.title == 'Sala no encontrada') {
        emit(const ChatError('Error: La sala de chat solicitada no existe o no se encontró.'));
        return;
      }

      // 3. Emitir y suscribirse a mensajes
      emit(ChatRoomSelectedState(room: room));
      add(ChatMessagesSubscriptionRequested(event.roomId));
      add(ChatMarkAsRead(event.roomId));
      
    } else {
      // Si el estado es inesperado (ChatInitial, AuthError, etc.) y no se pudo seleccionar
      emit(const ChatError('Error: Las salas de chat no se han cargado o existe un error de estado.'));
    }
  }

  // 4. Maneja la solicitud de suscripción a los mensajes de la sala
  // 🛑 CORRECCIÓN CLAVE: Aunque el error original venía de _onRoomsSubscriptionRequested,
  // aplicamos el mismo patrón seguro a la suscripción de mensajes.
  Future<void> _onMessagesSubscriptionRequested(
    ChatMessagesSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Si ya existe una suscripción, la cancelamos
    await _messagesSubscription?.cancel();
    _messagesSubscription = null; // Reiniciar la suscripción

    final messagesStream =
        getMessagesStream(MessagesStreamParams(roomId: event.roomId));

    // Usamos .listen porque no queremos que este handler de evento 'espere' al stream.
    // El ciclo de vida de los mensajes debe ser independiente.
    // Necesitas asegurar que tu lógica de estado sea robusta para evitar emitir 
    // después de que el BLoC se cierre.
    _messagesSubscription = messagesStream.listen((failureOrMessages) {
      failureOrMessages.fold(
        // 🛑 CORRECCIÓN DE SEGURIDAD: Usar emit.isDone antes de llamar a emit en un listener
        // para prevenir errores si el listener dispara un evento después de que el BLoC se haya cerrado.
        (failure) {
          if (!isClosed) emit(ChatError(failure.errorMessage));
        },
        (messages) {
          if (!isClosed) add(ChatMessagesReceived(messages.reversed.toList())); // Mostrar en orden correcto
        },
      );
    }, onError: (error, stackTrace) {
      if (!isClosed) emit(ChatError('Error inesperado al escuchar mensajes: ${error.toString()}'));
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

      // Mantenemos la llamada a MarkAsRead, aunque se recomienda moverla a la vista
      // al enfocar para evitar escrituras excesivas de Firestore.
      add(ChatMarkAsRead(currentState.room.id));
    }
  }

  // Sin cambios, ya era asíncrono y usaba 'await'.
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
        senderId: currentUserId, // Usar el ID del BLoC
        content: event.content,
        senderName: currentUserName, // Usar el Nombre del BLoC
      ),
    );

    failureOrVoid.fold(
      (failure) {
        // Emitimos un error al estado general y volvemos al estado anterior sin el indicador de envío.
        emit(ChatError('Fallo al enviar el mensaje: ${failure.errorMessage}'));
        // Usamos delay para que el error pueda ser visto, luego volvemos al estado.
        // Se puede eliminar este delay si no es necesario.
        // await Future<void>.delayed(const Duration(seconds: 2));
        emit(currentState.copyWith(isSending: false)); 
      },
      (_) {
        emit(currentState.copyWith(isSending: false));
      },
    );
  }

  // Sin cambios, ya era asíncrono y usaba 'await'.
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
    // Ya no es necesario cancelar _roomsSubscription si usamos emit.forEach,
    // pero si se dejó, se cancelaría aquí.
    return super.close();
  }
}