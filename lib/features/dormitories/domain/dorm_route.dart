import 'package:latlong2/latlong.dart';

class DormRoute {
  const DormRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> geometry;

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return 'Est. $minutes min drive';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? 'Est. $hours hr drive'
        : 'Est. $hours hr $remainingMinutes min drive';
  }
}
