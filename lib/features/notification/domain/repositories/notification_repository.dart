import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/notification_config.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationConfig>>> getNotificationConfigs();
}
