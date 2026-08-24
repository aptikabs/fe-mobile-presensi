import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/notification_config.dart';
import '../repositories/notification_repository.dart';

class GetNotificationConfigsUseCase {
  final NotificationRepository repository;

  GetNotificationConfigsUseCase(this.repository);

  Future<Either<Failure, List<NotificationConfig>>> call() async {
    return await repository.getNotificationConfigs();
  }
}
