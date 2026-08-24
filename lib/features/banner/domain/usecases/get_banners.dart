import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/banner.dart';
import '../repositories/banner_repository.dart';

class GetBanners {
  final BannerRepository repository;

  GetBanners(this.repository);

  Future<Either<Failure, List<BannerEntity>>> call() async {
    return await repository.getBanners();
  }
}
