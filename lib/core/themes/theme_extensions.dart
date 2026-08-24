import 'package:flutter/material.dart';

@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  final List<BoxShadow> shadows;

  const AppShadows({required this.shadows});

  static const light = AppShadows(
    shadows: [
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 8),
    ],
  );

  static const dark = AppShadows(
    shadows: [
      BoxShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  @override
  AppShadows copyWith({List<BoxShadow>? shadows}) =>
      AppShadows(shadows: shadows ?? this.shadows);

  @override
  AppShadows lerp(AppShadows? other, double t) {
    if (other == null) return this;
    return AppShadows(shadows: shadows);
  }
}
