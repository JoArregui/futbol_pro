import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/usecases/usecase.dart';

class SubscribeToNotifications implements UseCase<void, SubscribeParams> {
  final NotificationService service;

  SubscribeToNotifications(this.service);

  @override
  Future<Either<Failure, void>> call(SubscribeParams params) async {
    try {
      if (params.topic.isNotEmpty) {
        await service.subscribeToTopic(params.topic);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class SubscribeParams extends Equatable {
  final String topic;

  const SubscribeParams({required this.topic});

  @override
  List<Object> get props => [topic];
}
