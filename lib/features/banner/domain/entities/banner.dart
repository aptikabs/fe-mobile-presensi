import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  final int id;
  final String title;
  final String description;
  final String image;
  final String imageUrl;
  final String createdAt;

  const BannerEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.imageUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    image,
    imageUrl,
    createdAt,
  ];
}
