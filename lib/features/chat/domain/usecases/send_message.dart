/* Future<void> sendMessage(String chatRoomId, String content) async {
  final currentUser = FirebaseAuth.instance.currentUser!;
  
  await FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatRoomId)
    .collection('messages')
    .add({
      'senderId': currentUser.uid,
      'senderName': currentUser.displayName,
      'content': content,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    }); */



import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart'; 
import '../repositories/chat_repository.dart';

class SendMessage implements UseCase<void, SendParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(SendParams params) async {
    if (params.content.trim().isEmpty) {
      return Left(const ValidationFailure('El mensaje no puede estar vacío.'));
    }

    return await repository.sendMessage(
      roomId: params.roomId,
      senderId: params.senderId,
      // Asumimos que el senderName se recupera en la capa de datos o es parte de la entidad de usuario
      senderName: params.senderName, // <--- El BLoC NO envía senderName, lo agregamos aquí por consistencia
      text: params.content,
    );
  }
}

class SendParams extends Equatable {
  final String roomId;
  final String senderId;
  final String content;
  // Añadimos senderName que falta en el BLoC y en el evento
  final String senderName; 

  const SendParams({
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.senderName, // Asumiendo que el BLoC obtendrá el nombre
  });

  @override
  List<Object> get props => [roomId, senderId, content, senderName];
}