import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
// 🟢 CORRECCIÓN: Usar la interfaz base correcta 'UseCase'
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

// 🟢 CORRECCIÓN: Implementar la clase base UseCase<T, P>
class GetChatRooms implements UseCase<List<ChatRoom>, UserIdParams> {
  final ChatRepository repository;

  GetChatRooms(this.repository);

  @override
  // 🟢 CORRECCIÓN: El método 'call' ahora devuelve un Future<Either<Failure, T>>
  Future<Either<Failure, List<ChatRoom>>> call(UserIdParams params) {
    // Llama al método de repositorio que ahora devuelve un Future
    return repository.getChatRooms(params.userId);
  }
}

class UserIdParams extends Equatable {
  final String userId;

  const UserIdParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
