import 'package:dorm_the_explorer/features/dormitories/domain/dorm_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DormRoute travel time estimates', () {
    test('estimates walking and biking from the route distance', () {
      const route = DormRoute(
        distanceMeters: 1000,
        durationSeconds: 125,
        geometry: [],
      );

      expect(route.walkingDurationLabel, '~12 min');
      expect(route.bikingDurationLabel, '~4 min');
    });

    test('uses road route duration as the motorcycle estimate', () {
      const route = DormRoute(
        distanceMeters: 1000,
        durationSeconds: 125,
        geometry: [],
      );

      expect(route.drivingDurationLabel, '~3 min');
      expect(route.motorcycleDurationLabel, '~3 min');
    });

    test('formats longer estimates in hours and minutes', () {
      const route = DormRoute(
        distanceMeters: 6000,
        durationSeconds: 3600,
        geometry: [],
      );

      expect(route.walkingDurationLabel, '~1 hr 12 min');
      expect(route.bikingDurationLabel, '~24 min');
      expect(route.motorcycleDurationLabel, '~1 hr');
    });
  });
}
