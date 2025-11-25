import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
// 🟢 CORRECCIÓN: Usar la interfaz base correcta 'UseCase'
import '../../../../core/usecases/usecase.dart'; 
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

// 🟢 CORRECCIÓN: Implementar la clase base UseCase<T, P>
class GetMessages implements UseCase<List<Message>, MessagesParams> {
  final ChatRepository repository;

  GetMessages(this.repository);

  @override
  // 🟢 CORRECCIÓN: El método 'call' ahora devuelve un Future<Either<Failure, T>>
  Future<Either<Failure, List<Message>>> call(MessagesParams params) {
    // Llama al método de repositorio que ahora devuelve un Future
    return repository.getMessages(params.roomId);
  }
}

// 🔄 CAMBIO DE NOMBRE: De StreamParams a Params
class MessagesParams extends Equatable {
  final String roomId;
  const MessagesParams({required this.roomId});

  @override
  List<Object> get props => [roomId];
}