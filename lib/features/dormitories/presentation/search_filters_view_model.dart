import 'package:flutter/foundation.dart';

import '../domain/dormitory_search_filters.dart';

class SearchFiltersViewModel extends ChangeNotifier {
  SearchFiltersViewModel({
    DormitorySearchFilters? initialFilters,
    String initialQuery = '',
  }) : _query = initialFilters?.query ?? initialQuery,
      _priceRange = initialFilters == null
          ? DormPriceRange.budget
          : initialFilters.priceRange,
      _slotRange = initialFilters == null
          ? DormSlotRange.oneToTwo
          : initialFilters.slotRange,
      _amenities = initialFilters == null
          ? {'wifi', 'own_cr', 'aircon'}
          : Set.of(initialFilters.amenities),
      _campus = initialFilters == null
          ? DormCampus.alangilan
          : initialFilters.campus;

  String _query;
  DormPriceRange? _priceRange;
  DormSlotRange? _slotRange;
  final Set<String> _amenities;
  DormCampus? _campus;

  String get query => _query;
  DormPriceRange? get priceRange => _priceRange;
  DormSlotRange? get slotRange => _slotRange;
  Set<String> get amenities => Set.unmodifiable(_amenities);
  DormCampus? get campus => _campus;

  DormitorySearchFilters get filters => DormitorySearchFilters(
    query: _query,
    priceRange: _priceRange,
    slotRange: _slotRange,
    amenities: _amenities,
    campus: _campus,
  );

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void selectPriceRange(DormPriceRange? value) {
    _priceRange = value;
    notifyListeners();
  }

  void selectSlotRange(DormSlotRange? value) {
    _slotRange = value;
    notifyListeners();
  }

  void toggleAmenity(String value) {
    if (!_amenities.add(value)) _amenities.remove(value);
    notifyListeners();
  }

  void toggleCampus(DormCampus value) {
    _campus = _campus == value ? null : value;
    notifyListeners();
  }

  void clearAll() {
    _query = '';
    _priceRange = null;
    _slotRange = null;
    _amenities.clear();
    _campus = null;
    notifyListeners();
  }
}
