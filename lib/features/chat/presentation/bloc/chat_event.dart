part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

/// Evento para inicializar y cargar las salas de chat disponibles.
class ChatRoomsSubscriptionRequested extends ChatEvent {}

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

/// Evento para enviar un nuevo mensaje.
class ChatMessageSent extends ChatEvent {
  final String content;
  final String roomId;
  final String senderId;

  const ChatMessageSent({
    required this.content,
    required this.roomId,
    required this.senderId,
  });

  @override
  List<Object> get props => [content, roomId, senderId];
}

/// Evento para marcar los mensajes de una sala como leídos.
class ChatMarkAsRead extends ChatEvent {
  final String roomId;

  const ChatMarkAsRead(this.roomId);

  @override
  List<Object> get props => [roomId];
}


class ChatRoomsReceived extends ChatEvent {
  final List<ChatRoom> rooms;

  const ChatRoomsReceived(this.rooms);

  @override
  List<Object> get props => [rooms];
}