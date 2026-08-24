import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../core/services/notification_service.dart';
import '../../core/network/network_info.dart';
import '../../core/presentation/bloc/connectivity_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth/auth_cubit.dart';
import '../../features/history/data/datasources/history_remote_data_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/get_attendance_logs.dart';
import '../../features/history/domain/usecases/get_history.dart';
import '../../features/history/presentation/bloc/history/history_cubit.dart';
import '../../features/history/presentation/bloc/log/log_cubit.dart';
import '../../features/notification/data/datasources/notification_remote_data_source.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/domain/usecases/get_notification_config_usecase.dart';
import '../../features/notification/presentation/bloc/notification_cubit.dart';

class AppProviders {
  static List<RepositoryProvider> getRepositories(
    Box authBox,
    http.Client client,
    NetworkInfo networkInfo,
  ) {
    // Data Sources
    final authLocalDataSource = AuthLocalDataSourceImpl(box: authBox);
    final authRemoteDataSource = AuthRemoteDataSourceImpl(client: client);

    final historyRemoteDataSource = HistoryRemoteDataSourceImpl(client: client);

    final notificationRemoteDataSource = NotificationRemoteDataSourceImpl(
      client: client,
    );

    // Services
    final notificationService = NotificationService();

    // Repositories
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      localDataSource: authLocalDataSource,
      networkInfo: networkInfo,
    );

    final historyRepository = HistoryRepositoryImpl(
      remoteDataSource: historyRemoteDataSource,
      networkInfo: networkInfo,
    );

    final notificationRepository = NotificationRepositoryImpl(
      remoteDataSource: notificationRemoteDataSource,
    );

    // UseCases
    final getAttendanceLogs = GetAttendanceLogs(historyRepository);
    final getNotificationConfigsUseCase = GetNotificationConfigsUseCase(
      notificationRepository,
    );

    return [
      RepositoryProvider<NetworkInfo>(create: (_) => networkInfo),
      RepositoryProvider<AuthRepository>(create: (_) => authRepository),
      RepositoryProvider<HistoryRepository>(create: (_) => historyRepository),
      RepositoryProvider<NotificationRepository>(
        create: (_) => notificationRepository,
      ),
      RepositoryProvider<GetAttendanceLogs>(create: (_) => getAttendanceLogs),
      RepositoryProvider<GetHistory>(
        create: (_) => GetHistory(historyRepository),
      ),
      RepositoryProvider<GetNotificationConfigsUseCase>(
        create: (_) => getNotificationConfigsUseCase,
      ),
      RepositoryProvider<NotificationService>(
        create: (_) => notificationService,
      ),
      RepositoryProvider<AuthLocalDataSource>(
        create: (_) => authLocalDataSource,
      ),
    ];
  }

  static List<BlocProvider> getBlocs(
    Box settingsBox,
    NetworkInfo networkInfo,
  ) {
    return [
      BlocProvider<ConnectivityCubit>(
        create: (_) => ConnectivityCubit(networkInfo: networkInfo),
      ),
      BlocProvider<AuthCubit>(
        create: (context) => AuthCubit(
          localDataSource: context.read<AuthLocalDataSource>(),
          authRepository: context.read<AuthRepository>(),
        )..checkAuthStatus(),
      ),
      BlocProvider<LogCubit>(
        create: (context) =>
            LogCubit(getAttendanceLogs: context.read<GetAttendanceLogs>()),
      ),
      BlocProvider<HistoryCubit>(
        create: (context) =>
            HistoryCubit(getHistory: context.read<GetHistory>()),
      ),
      BlocProvider<NotificationCubit>(
        create: (context) => NotificationCubit(
          getNotificationConfigs: context.read<GetNotificationConfigsUseCase>(),
          notificationService: context.read<NotificationService>(),
          settingsBox: settingsBox,
        ),
      ),
    ];
  }
}
