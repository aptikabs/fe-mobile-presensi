import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/presence_log.dart';
import '../repositories/history_repository.dart';

class GetHistory {
  final HistoryRepository repository;

  GetHistory(this.repository);

  Future<Either<Failure, List<PresenceLog>>> call({
    required String nip,
    required String startDate,
    required String endDate,
    String? token,
  }) async {
    return await repository.getHistory(
      nip,
      startDate,
      endDate,
      token: token,
    );
  }
}
