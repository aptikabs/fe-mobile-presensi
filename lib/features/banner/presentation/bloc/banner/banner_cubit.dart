import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/usecases/get_banners.dart';
import 'banner_state.dart';

class BannerCubit extends Cubit<BannerState> {
  final GetBanners getBanners;

  BannerCubit({required this.getBanners}) : super(BannerInitial());

  Future<void> loadBanners() async {
    emit(BannerLoading());
    final result = await getBanners();
    result.fold((failure) {
      if (failure is ServerFailure) {
        emit(BannerError(failure.message));
      } else {
        emit(const BannerError('Gagal memuat banner'));
      }
    }, (banners) => emit(BannerLoaded(banners)));
  }
}
