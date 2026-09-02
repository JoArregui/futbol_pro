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

class ChatRoomSelectedState extends ChatState {
  final ChatRoom room;
  final List<Message> messages;
  final bool isSending;
  final bool isTyping; // alguien escribiendo
  final String? typingUserId;
  const ChatRoomSelectedState({
    required this.room,
    this.messages = const [],
    this.isSending = false,
    this.isTyping = false,
    this.typingUserId,
  });
  ChatRoomSelectedState copyWith({List<Message>? messages, bool? isSending, bool? isTyping, String? typingUserId}) => ChatRoomSelectedState(
        room: room,
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        isTyping: isTyping ?? this.isTyping,
        typingUserId: typingUserId,
      );
  @override
  List<Object?> get props => [room, messages, isSending, isTyping, typingUserId];
}

class ChatSearchState extends ChatState {
  final List<Map<String, dynamic>> users;
  final bool isSearching;
  const ChatSearchState({this.users = const [], this.isSearching = false});
  @override
  List<Object?> get props => [users, isSearching];
}