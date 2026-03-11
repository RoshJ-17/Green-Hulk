import 'dart:math';

/// Utility class for geographic calculations.
class GeoUtils {
  /// Calculates the distance between two points on Earth using the Haversine formula.
  /// Returns the distance in kilometers.
  static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;
}
