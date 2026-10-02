part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// 🟢 Evento para inicializar y cargar las salas de chat disponibles (La clase que faltaba).
class ChatRoomsSubscriptionRequested extends ChatEvent {}

/// Actualiza los metadatos de las salas sin desmontar la sala abierta.
class ChatRoomsBackgroundRefreshRequested extends ChatEvent {}

/// Evento disparado cuando se selecciona una sala de chat específica.
class ChatRoomSelected extends ChatEvent {
  final String roomId;

  const ChatRoomSelected(this.roomId);

  @override
  List<Object> get props => [roomId];
}

/// Evento que inicia la escucha en tiempo real de mensajes para la sala seleccionada.
class ChatMessagesSubscriptionRequested extends ChatEvent {
  final String roomId;

  const ChatMessagesSubscriptionRequested(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class ChatMessagesReceived extends ChatEvent {
  final List<Message> messages;

  const ChatMessagesReceived(this.messages);

  @override
  List<Object> get props => [messages];
}

/// Evento para enviar un nuevo mensaje (texto y/o imagen).
class ChatMessageSent extends ChatEvent {
  final String content;
  final String roomId;
  final String? imageUrl;

  const ChatMessageSent({
    required this.content,
    required this.roomId,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [content, roomId, imageUrl];
}

/// Evento para marcar los mensajes de una sala como leídos.
class ChatMarkAsRead extends ChatEvent {
  final String roomId;

  const ChatMarkAsRead(this.roomId);

  @override
  List<Object> get props => [roomId];
}

/// Sale de la conversación abierta sin recargar la lista con ChatLoading.
class ChatRoomLeft extends ChatEvent {
  final String roomId;
  const ChatRoomLeft(this.roomId);
  @override
  List<Object> get props => [roomId];
}

class ChatRoomsReceived extends ChatEvent {
  final List<ChatRoom> rooms;
  const ChatRoomsReceived(this.rooms);
  @override
  List<Object> get props => [rooms];
}

class ChatCreateRequested extends ChatEvent {
  final String title;
  final String type;
  final List<String> memberIds;
  const ChatCreateRequested({
    required this.title,
    required this.type,
    required this.memberIds,
  });
  @override
  List<Object> get props => [title, type, memberIds];
}

class ChatSearchRequested extends ChatEvent {
  final String query;
  const ChatSearchRequested(this.query);
  @override
  List<Object> get props => [query];
}

class ChatTypingChanged extends ChatEvent {
  final String roomId;
  final bool isTyping;
  const ChatTypingChanged({required this.roomId, required this.isTyping});
  @override
  List<Object> get props => [roomId, isTyping];
}

class ChatSocketMessageReceived extends ChatEvent {
  final Message message;
  final String roomId;

  /// Id cliente del remitente para reconciliar el optimista (puede ser null).
  final String? clientId;
  const ChatSocketMessageReceived({
    required this.message,
    required this.roomId,
    this.clientId,
  });
  @override
  List<Object?> get props => [message, roomId, clientId];
}

class ChatSocketTypingReceived extends ChatEvent {
  final String roomId;
  final String userId;
  final bool isTyping;
  const ChatSocketTypingReceived({
    required this.roomId,
    required this.userId,
    required this.isTyping,
  });
  @override
  List<Object> get props => [roomId, userId, isTyping];
}
