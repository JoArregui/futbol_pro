part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Estado Inicial y cuando la aplicación está cargando
class ChatInitial extends ChatState {}

/// Estado durante cualquier operación que requiera esperar (cargando salas, enviando mensaje)
class ChatLoading extends ChatState {}

/// Estado de error
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

/// ------------------------------------------
/// ESTADOS DE LA LISTA DE SALAS (CHAT LIST)
/// ------------------------------------------

/// Estado cuando se han cargado las salas de chat disponibles.
class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> rooms;

  const ChatRoomsLoaded({required this.rooms});

  @override
  List<Object> get props => [rooms];
}

/// ------------------------------------------
/// ESTADOS DE LA SALA DE CHAT ACTIVA (CHAT ROOM)
/// ------------------------------------------

/// Estado cuando se ha entrado a una sala específica y se están cargando los mensajes.
class ChatRoomSelectedState extends ChatState {
  final ChatRoom room;
  final List<Message> messages;
  final bool isSending; // Indica si un mensaje está en proceso de envío

  const ChatRoomSelectedState({
    required this.room,
    this.messages = const [],
    this.isSending = false,
  });

  // Método helper para crear un nuevo estado con mensajes actualizados
  ChatRoomSelectedState copyWith({
    List<Message>? messages,
    bool? isSending,
  }) {
    return ChatRoomSelectedState(
      room: room,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [room, messages, isSending];
}