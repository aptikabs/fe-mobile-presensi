import 'package:epresensi_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/pinned_http_client.dart';

import '../../../../app/router/app_routes_names.dart';
import '../../data/datasources/banner_remote_data_source.dart';
import '../../data/repositories/banner_repository_impl.dart';
import '../../domain/usecases/get_banners.dart';
import '../bloc/banner/banner_state.dart';
import '../bloc/banner/banner_cubit.dart';

class BannerPage extends StatelessWidget {
  const BannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DI setup locally for now, similar to HomePage
    final remoteDataSource = BannerRemoteDataSourceImpl(client: PinnedHttpClient.createClient());
    final repository = BannerRepositoryImpl(remoteDataSource: remoteDataSource);
    final getBanners = GetBanners(repository);

    return BlocProvider(
      create: (context) => BannerCubit(getBanners: getBanners)..loadBanners(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pengumuman',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primary700,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<BannerCubit, BannerState>(
          builder: (context, state) {
            if (state is BannerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BannerError) {
              return Center(child: Text(state.message));
            } else if (state is BannerLoaded) {
              if (state.banners.isEmpty) {
                return const Center(child: Text('Tidak ada pengumuman'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.banners.length,
                itemBuilder: (context, index) {
                  final banner = state.banners[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neutral900.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.push(
                            AppRouteNames.bannerDetail,
                            extra: banner,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Compact Image Thumbnail
                              Hero(
                                tag: 'banner_image_${banner.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 100,
                                    height: 80,
                                    child: Image.network(
                                      banner.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.neutral200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 24,
                                          color: AppColors.neutral500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        banner.createdAt.split('T').first,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      banner.description.isEmpty
                                          ? 'Klik untuk selengkapnya'
                                          : banner.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.neutral400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
