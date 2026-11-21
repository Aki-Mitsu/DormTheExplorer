import 'package:flutter_test/flutter_test.dart';
import 'package:dorm_the_explorer/features/dormitories/domain/dormitory.dart';
import 'package:dorm_the_explorer/features/dormitories/domain/dormitory_search_filters.dart';
import 'package:dorm_the_explorer/features/dormitories/domain/route_destination.dart';

void main() {
  group('campus proximity filters', () {
    test('central campus list contains all eight campuses', () {
      expect(
        RouteDestination.campuses.map((campus) => campus.name),
        equals([
          'BatStateU Alangilan',
          'BatStateU Pablo Borbon',
          'Lyceum of the Philippines University',
          'University of Batangas',
          'Golden Gate Colleges',
          'St. Bridget College',
          'STI College - Batangas',
          'Westmead International School',
        ]),
      );
    });

    test('each campus matches a dormitory at its actual coordinates', () {
      for (final campus in RouteDestination.campuses) {
        final dormitory = _dormitoryAt(
          latitude: campus.location.latitude,
          longitude: campus.location.longitude,
        );
        final filters = DormitorySearchFilters(campus: campus);

        expect(filters.matches(dormitory), isTrue, reason: campus.name);
      }
    });

    test('campus filter excludes dormitories without coordinates', () {
      final filters = DormitorySearchFilters(
        campus: RouteDestination.campuses.last,
      );

      expect(filters.matches(_dormitoryAt()), isFalse);
    });
  });
}

Dormitory _dormitoryAt({double? latitude, double? longitude}) => Dormitory(
  id: 'test-dormitory',
  landlordId: 'test-landlord',
  name: 'Test dormitory',
  address: 'Batangas City',
  monthlyPrice: 3000,
  availableSlots: 1,
  totalSlots: 1,
  amenities: const [],
  description: '',
  photoUrls: const [],
  status: 'approved',
  latitude: latitude,
  longitude: longitude,
);
