import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/banner.dart';

abstract class BannerRepository {
  Future<Either<Failure, List<BannerEntity>>> getBanners();
}
