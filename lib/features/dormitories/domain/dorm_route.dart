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
    return 'Est. ${_formatMinutes(minutes)} drive';
  }

  String get walkingDurationLabel =>
      '~${_formatMinutes(_estimatedMinutes(speedKilometersPerHour: 5))}';

  String get bikingDurationLabel =>
      '~${_formatMinutes(_estimatedMinutes(speedKilometersPerHour: 15))}';

  String get drivingDurationLabel =>
      '~${_formatMinutes((durationSeconds / 60).ceil())}';

  String get motorcycleDurationLabel => drivingDurationLabel;

  int _estimatedMinutes({required double speedKilometersPerHour}) =>
      (distanceMeters / 1000 / speedKilometersPerHour * 60).ceil();

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '$hours hr'
        : '$hours hr $remainingMinutes min';
  }
}
