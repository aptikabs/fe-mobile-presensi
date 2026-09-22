import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationUtils {
  /// Check if a point is inside a polygon using Ray Casting algorithm
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      int next = (j + 1) % polygon.length;
      if (((polygon[j].latitude <= point.latitude &&
                  point.latitude < polygon[next].latitude) ||
              (polygon[next].latitude <= point.latitude &&
                  point.latitude < polygon[j].latitude)) &&
          (point.longitude <
              (polygon[next].longitude - polygon[j].longitude) *
                      (point.latitude - polygon[j].latitude) /
                      (polygon[next].latitude - polygon[j].latitude) +
                  polygon[j].longitude)) {
        intersectCount++;
      }
    }
    return intersectCount % 2 != 0;
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  /// Check if a point is within the configured circular radius
  static bool isWithinRadius(
    LatLng point,
    LatLng center,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      point.latitude,
      point.longitude,
      center.latitude,
      center.longitude,
    );
    return distance <= radiusInMeters;
  }
}
