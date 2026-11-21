import 'package:latlong2/latlong.dart';

import 'dormitory.dart';
import 'route_destination.dart';

enum DormPriceRange { budget, midRange, premium }

enum DormSlotRange { oneToTwo, threeToFour, fiveOrMore }

enum DormCampus { alangilan, pabloBorbon, lpu }

class DormitorySearchFilters {
  DormitorySearchFilters({
    this.query = '',
    this.priceRange,
    this.slotRange,
    Set<String> amenities = const {},
    this.campus,
    this.sortByRating = false,
  }) : amenities = Set.unmodifiable(amenities);

  final String query;
  final DormPriceRange? priceRange;
  final DormSlotRange? slotRange;
  final Set<String> amenities;
  final DormCampus? campus;
  final bool sortByRating;

  static const double campusRadiusKm = 3;
  static const Distance _distance = Distance();

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      priceRange != null ||
      slotRange != null ||
      amenities.isNotEmpty ||
      campus != null;

  bool matches(Dormitory dormitory) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty &&
        !dormitory.name.toLowerCase().contains(normalizedQuery) &&
        !dormitory.address.toLowerCase().contains(normalizedQuery)) {
      return false;
    }

    if (priceRange case final range?) {
      final price = dormitory.monthlyPrice.toDouble();
      final matchesPrice = switch (range) {
        DormPriceRange.budget => price <= 3000,
        DormPriceRange.midRange => price >= 3000 && price <= 5000,
        DormPriceRange.premium => price >= 5000,
      };
      if (!matchesPrice) return false;
    }

    if (slotRange case final range?) {
      final matchesSlots = switch (range) {
        DormSlotRange.oneToTwo =>
          dormitory.availableSlots >= 1 && dormitory.availableSlots <= 2,
        DormSlotRange.threeToFour =>
          dormitory.availableSlots >= 3 && dormitory.availableSlots <= 4,
        DormSlotRange.fiveOrMore => dormitory.availableSlots >= 5,
      };
      if (!matchesSlots) return false;
    }

    if (amenities.isNotEmpty) {
      final available = dormitory.amenities.map(_normalize).toSet();
      if (!amenities.map(_normalize).every(available.contains)) return false;
    }

    if (campus case final selectedCampus?) {
      final index = DormCampus.values.indexOf(selectedCampus);
      final destination = RouteDestination.campuses[index];
      final latitude = dormitory.latitude;
      final longitude = dormitory.longitude;
      if (latitude != null && longitude != null) {
        final distance = _distance.as(
          LengthUnit.Kilometer,
          destination.location,
          LatLng(latitude, longitude),
        );
        if (distance > campusRadiusKm) return false;
      } else if (!(dormitory.proximityLabel ?? '')
          .toLowerCase()
          .contains(_campusSearchToken(selectedCampus))) {
        return false;
      }
    }

    return true;
  }

  DormitorySearchFilters copyWith({String? query, bool? sortByRating}) =>
      DormitorySearchFilters(
        query: query ?? this.query,
        priceRange: priceRange,
        slotRange: slotRange,
        amenities: amenities,
        campus: campus,
        sortByRating: sortByRating ?? this.sortByRating,
      );

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String _campusSearchToken(DormCampus campus) => switch (campus) {
    DormCampus.alangilan => 'alangilan',
    DormCampus.pabloBorbon => 'pablo borbon',
    DormCampus.lpu => 'lpu',
  };
}
