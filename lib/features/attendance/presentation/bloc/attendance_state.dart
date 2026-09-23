import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendancePermissionRequired extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final Position? currentPosition;
  final bool isInsideRadius;
  final bool isWfa;
  final bool isLibur;
  final Set<Circle> circles;
  final Set<Polygon> polygons;
  final String? errorMessage;
  final bool isLoadingLocation;
  final double? distanceToNearest;
  final double? radiusToNearest;
  final String? nearestPlaceName;
  final bool isSubmitting;
  final String? submissionSuccessMessage;
  final String? submissionErrorMessage;

  const AttendanceLoaded({
    this.currentPosition,
    this.isInsideRadius = false,
    this.isWfa = false,
    this.isLibur = false,
    this.circles = const {},
    this.polygons = const {},
    this.errorMessage,
    this.isLoadingLocation = false,
    this.distanceToNearest,
    this.radiusToNearest,
    this.nearestPlaceName,
    this.isSubmitting = false,
    this.submissionSuccessMessage,
    this.submissionErrorMessage,
  });

  AttendanceLoaded copyWith({
    Position? currentPosition,
    bool? isInsideRadius,
    bool? isWfa,
    bool? isLibur,
    Set<Circle>? circles,
    Set<Polygon>? polygons,
    String? errorMessage,
    bool? isLoadingLocation,
    double? distanceToNearest,
    double? radiusToNearest,
    String? nearestPlaceName,
    bool? isSubmitting,
    String? submissionSuccessMessage,
    String? submissionErrorMessage,
  }) {
    return AttendanceLoaded(
      currentPosition: currentPosition ?? this.currentPosition,
      isInsideRadius: isInsideRadius ?? this.isInsideRadius,
      isWfa: isWfa ?? this.isWfa,
      isLibur: isLibur ?? this.isLibur,
      circles: circles ?? this.circles,
      polygons: polygons ?? this.polygons,
      errorMessage: errorMessage,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      distanceToNearest: distanceToNearest ?? this.distanceToNearest,
      radiusToNearest: radiusToNearest ?? this.radiusToNearest,
      nearestPlaceName: nearestPlaceName ?? this.nearestPlaceName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionSuccessMessage: submissionSuccessMessage,
      submissionErrorMessage: submissionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    currentPosition,
    isInsideRadius,
    isWfa,
    isLibur,
    circles,
    polygons,
    errorMessage,
    isLoadingLocation,
    distanceToNearest,
    radiusToNearest,
    nearestPlaceName,
    isSubmitting,
    submissionSuccessMessage,
    submissionErrorMessage,
  ];
}

class AttendanceCameraPermissionRequired extends AttendanceState {}

class AttendanceSecurityBlocked extends AttendanceState {
  final String message;
  final bool isDeveloperMode;

  const AttendanceSecurityBlocked(this.message, {this.isDeveloperMode = false});

  @override
  List<Object> get props => [message, isDeveloperMode];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object> get props => [message];
}
