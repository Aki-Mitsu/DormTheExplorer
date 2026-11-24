import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import '../domain/dormitory_search_filters.dart';

class DormDashboardViewModel extends ChangeNotifier {
  DormDashboardViewModel({
    required this.repository,
    required this.accountRole,
    required this.userId,
  }) {
    _subscribe();
  }

  final DormitoryRepository repository;
  final String accountRole;
  final String userId;

  StreamSubscription<List<Dormitory>>? _subscription;
  List<Dormitory> _dormitories = const [];
  final Set<String> _favoriteIds = {};
  String _searchQuery = '';
  DormitorySearchFilters? _searchFilters;
  bool _isLoading = true;
  bool _showFavoritesOnly = false;
  bool _showLandlordListings = false;
  Object? _error;

  bool get isLandlord => accountRole == 'landlord';
  bool get isLoading => _isLoading;
  Object? get error => _error;
  bool get showFavoritesOnly => _showFavoritesOnly;
  String get searchQuery => _searchQuery;
  DormitorySearchFilters? get searchFilters => _searchFilters;
  bool isFavorite(String dormitoryId) => _favoriteIds.contains(dormitoryId);

  List<Dormitory> get visibleDormitories {
    Iterable<Dormitory> results = _dormitories;

    if (!isLandlord && _showFavoritesOnly) {
      results = results.where(
        (dormitory) => _favoriteIds.contains(dormitory.id),
      );
    }

    if (_searchFilters case final filters?) {
      results = results.where(filters.matches);
    } else {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        results = results.where((dormitory) {
          final searchableText = [
            dormitory.name,
            dormitory.address,
            ...dormitory.amenities,
          ].join(' ').toLowerCase();
          return searchableText.contains(query);
        });
      }
    }

    final filteredDormitories = results.toList(growable: false);
    final filters = _searchFilters;
    if (filters == null ||
        !filters.sortByRating ||
        !filters.hasActiveFilters) {
      return filteredDormitories;
    }

    final rankedDormitories = <(int, Dormitory)>[
      for (var index = 0; index < filteredDormitories.length; index++)
        (index, filteredDormitories[index]),
    ];
    rankedDormitories.sort((left, right) {
      final leftRating = left.$2.averageRating ?? -1;
      final rightRating = right.$2.averageRating ?? -1;
      final ratingOrder = rightRating.compareTo(leftRating);
      return ratingOrder != 0 ? ratingOrder : left.$1.compareTo(right.$1);
    });

    return rankedDormitories
        .map((entry) => entry.$2)
        .toList(growable: false);
  }

  void updateSearch(String value) {
    _searchQuery = value;
    if (_searchFilters case final filters?) {
      _searchFilters = filters.copyWith(query: value);
    }
    notifyListeners();
  }

  void applySearchFilters(DormitorySearchFilters filters) {
    _searchFilters = filters;
    _searchQuery = filters.query;
    notifyListeners();
  }

  void toggleFavorite(String dormitoryId) {
    setFavorite(dormitoryId, !isFavorite(dormitoryId));
  }

  void setFavorite(String dormitoryId, bool isFavorite) {
    if (isFavorite) {
      _favoriteIds.add(dormitoryId);
    } else {
      _favoriteIds.remove(dormitoryId);
    }
    notifyListeners();
  }

  void setFavoritesOnly(bool show) {
    if (_showFavoritesOnly == show) return;
    _showFavoritesOnly = show;
    notifyListeners();
  }

  void showAllDormitories() => setFavoritesOnly(false);

  void showLandlordListings(bool show) {
    if (!isLandlord || _showLandlordListings == show) return;
    _showLandlordListings = show;
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _subscribe();
  }

  void retry() {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    final stream = isLandlord && _showLandlordListings
        ? repository.watchLandlordDormitories(userId)
        : repository.watchApprovedDormitories();

    _subscription = stream.listen(
      (dormitories) {
        _dormitories = dormitories;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = error;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
