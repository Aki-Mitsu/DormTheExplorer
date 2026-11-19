import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import '../domain/route_destination.dart';

enum PriceBand { budget, midRange, premium }
enum SlotBand { oneToTwo, threeToFour, fiveOrMore }
enum DormSort { recommended, priceLow, priceHigh, rating }

class SearchFiltersViewModel extends ChangeNotifier {
  SearchFiltersViewModel({required this.repository, String initialQuery = ''})
      : query = initialQuery {
    _subscription = repository.watchApprovedDormitories().listen(
      (items) { dormitories = items; loading = false; error = null; notifyListeners(); },
      onError: (Object value) { loading = false; error = value; notifyListeners(); },
    );
  }
  final DormitoryRepository repository;
  static const campusRadiusKm = 3.0;
  static const _distance = Distance();
  StreamSubscription<List<Dormitory>>? _subscription;
  List<Dormitory> dormitories = const [];
  String query;
  PriceBand? price;
  SlotBand? slots;
  final Set<String> amenities = {};
  int? campusIndex;
  double rating = 0;
  DormSort sort = DormSort.recommended;
  bool loading = true;
  Object? error;

  List<Dormitory> get results {
    Iterable<Dormitory> list = dormitories;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((d) => [d.name, d.address, d.description, d.proximityLabel ?? '', ...d.amenities]
          .join(' ').toLowerCase().contains(q));
    }
    if (price case final band?) {
      list = list.where((d) {
        final value = d.monthlyPrice.toDouble();
        return switch (band) {
          PriceBand.budget => value >= 1000 && value <= 3000,
          PriceBand.midRange => value > 3000 && value <= 5000,
          PriceBand.premium => value >= 5000,
        };
      });
    }
    if (slots case final band?) {
      list = list.where((d) => switch (band) {
        SlotBand.oneToTwo => d.availableSlots >= 1 && d.availableSlots <= 2,
        SlotBand.threeToFour => d.availableSlots >= 3 && d.availableSlots <= 4,
        SlotBand.fiveOrMore => d.availableSlots >= 5,
      });
    }
    if (amenities.isNotEmpty) {
      list = list.where((d) {
        final have = d.amenities.map(_normalize).toSet();
        return amenities.every(have.contains);
      });
    }
    if (campusIndex case final index?) {
      final campus = RouteDestination.campuses[index];
      list = list.where((d) {
        if (d.latitude != null && d.longitude != null) {
          return _distance.as(LengthUnit.Kilometer, campus.location,
            LatLng(d.latitude!, d.longitude!)) <= campusRadiusKm;
        }
        final label = (d.proximityLabel ?? '').toLowerCase();
        return label.contains(switch(index) { 0 => 'alangilan', 1 => 'pablo borbon', _ => 'lpu' });
      });
    }
    if (rating > 0) list = list.where((d) => (d.averageRating ?? 0) >= rating);
    final output = list.toList();
    switch (sort) {
      case DormSort.recommended:
        output.sort((a, b) {
          final slotsOrder = b.availableSlots.compareTo(a.availableSlots);
          return slotsOrder != 0 ? slotsOrder :
            (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
        });
      case DormSort.priceLow: output.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
      case DormSort.priceHigh: output.sort((a, b) => b.monthlyPrice.compareTo(a.monthlyPrice));
      case DormSort.rating: output.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
    }
    return output;
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  void updateQuery(String value) { query = value; notifyListeners(); }
  void setPrice(PriceBand? value) { price = value; notifyListeners(); }
  void setSlots(SlotBand? value) { slots = value; notifyListeners(); }
  void toggleAmenity(String value) {
    if (!amenities.add(value)) amenities.remove(value);
    notifyListeners();
  }
  void setCampus(int? value) { campusIndex = value; notifyListeners(); }
  void setRating(double value) { rating = value; notifyListeners(); }
  void setSort(DormSort value) { sort = value; notifyListeners(); }
  void clear() {
    query = ''; price = null; slots = null; amenities.clear();
    campusIndex = null; rating = 0; sort = DormSort.recommended;
    notifyListeners();
  }
  void retry() {
    _subscription?.cancel();
    loading = true; error = null; notifyListeners();
    _subscription = repository.watchApprovedDormitories().listen(
      (items) { dormitories = items; loading = false; error = null; notifyListeners(); },
      onError: (Object value) { loading = false; error = value; notifyListeners(); },
    );
  }
  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
}
