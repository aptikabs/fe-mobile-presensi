import 'package:dartz/dartz.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../domain/entities/notification_config.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<NotificationConfig>>>
  getNotificationConfigs() async {
    try {
      final remoteConfigs = await remoteDataSource.getNotificationConfigs();
      return Right(
        remoteConfigs
            .map(
              (model) => NotificationConfig(
                id: model.id,
                title: model.title,
                body: model.body,
                timezone: model.timezone,
                schedule: NotificationSchedule(
                  hour: model.schedule.hour,
                  minute: model.schedule.minute,
                  type: model.schedule.type,
                  days: model.schedule.days,
                ),
              ),
            )
            .toList(),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
