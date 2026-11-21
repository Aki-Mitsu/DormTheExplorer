import 'package:flutter/foundation.dart';

import '../domain/dormitory_search_filters.dart';

class SearchFiltersViewModel extends ChangeNotifier {
  SearchFiltersViewModel({
    DormitorySearchFilters? initialFilters,
    String initialQuery = '',
  }) : _query = initialFilters?.query ?? initialQuery,
      _priceRange = initialFilters?.priceRange,
      _slotRange = initialFilters?.slotRange,
      _amenities = Set.of(initialFilters?.amenities ?? const <String>{}),
      _campus = initialFilters?.campus,
      _sortByRating = initialFilters?.sortByRating ?? true;

  String _query;
  DormPriceRange? _priceRange;
  DormSlotRange? _slotRange;
  final Set<String> _amenities;
  DormCampus? _campus;
  bool _sortByRating;

  String get query => _query;
  DormPriceRange? get priceRange => _priceRange;
  DormSlotRange? get slotRange => _slotRange;
  Set<String> get amenities => Set.unmodifiable(_amenities);
  DormCampus? get campus => _campus;
  bool get sortByRating => _sortByRating;

  DormitorySearchFilters get filters => DormitorySearchFilters(
    query: _query,
    priceRange: _priceRange,
    slotRange: _slotRange,
    amenities: _amenities,
    campus: _campus,
    sortByRating: _sortByRating,
  );

  void updateQuery(String value) {
    if (_query != value) _sortByRating = true;
    _query = value;
    notifyListeners();
  }

  void selectPriceRange(DormPriceRange? value) {
    final nextValue = _priceRange == value ? null : value;
    if (_priceRange != nextValue) _sortByRating = true;
    _priceRange = nextValue;
    notifyListeners();
  }

  void selectSlotRange(DormSlotRange? value) {
    final nextValue = _slotRange == value ? null : value;
    if (_slotRange != nextValue) _sortByRating = true;
    _slotRange = nextValue;
    notifyListeners();
  }

  void toggleAmenity(String value) {
    _sortByRating = true;
    if (!_amenities.add(value)) _amenities.remove(value);
    notifyListeners();
  }

  void selectCampus(DormCampus value) {
    final nextValue = _campus == value ? null : value;
    if (_campus != nextValue) _sortByRating = true;
    _campus = nextValue;
    notifyListeners();
  }

  void resetSort() {
    _sortByRating = false;
    notifyListeners();
  }

  void clearAll() {
    _query = '';
    _priceRange = null;
    _slotRange = null;
    _amenities.clear();
    _campus = null;
    _sortByRating = false;
    notifyListeners();
  }
}
