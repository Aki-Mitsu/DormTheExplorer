import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/dorm_review_repository.dart';
import '../data/osrm_routing_service.dart';
import '../domain/dorm_review.dart';
import '../domain/dorm_route.dart';
import '../domain/route_destination.dart';

class DormDetailsViewModel extends ChangeNotifier {
  DormDetailsViewModel({
    required this.dormitoryId,
    required DormReviewRepository reviewRepository,
    required this.routingService,
  }) : _reviewRepository = reviewRepository,
       _reviews = reviewRepository.reviewsFor(dormitoryId);

  final String dormitoryId;
  final DormReviewRepository _reviewRepository;
  final OsrmRoutingService routingService;

  List<DormReview> _reviews;
  List<DormReview> get reviews => List.unmodifiable(_reviews);

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        _reviews.length;
  }

  DormRoute? route;
  Object? routeError;
  bool isLoadingRoute = false;
  int _routeRequestId = 0;

  Future<void> loadRoute({
    required LatLng origin,
    required RouteDestination destination,
  }) async {
    final requestId = ++_routeRequestId;
    isLoadingRoute = true;
    route = null;
    routeError = null;
    notifyListeners();

    try {
      final nextRoute = await routingService.getDrivingRoute(
        origin: origin,
        destination: destination.location,
      );
      if (requestId == _routeRequestId) route = nextRoute;
    } catch (error) {
      if (requestId == _routeRequestId) routeError = error;
    } finally {
      if (requestId == _routeRequestId) {
        isLoadingRoute = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    routingService.dispose();
    super.dispose();
  }

  Future<void> submitReview({
    required String authorName,
    required int rating,
    required String comment,
  }) async {
    final review = DormReview(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      dormitoryId: dormitoryId,
      authorName: authorName,
      authorSubtitle: 'Student seeker',
      rating: rating,
      comment: comment,
      stayLabel: 'New review',
      createdAt: DateTime.now(),
    );
    await _reviewRepository.addReview(review);
    _reviews = _reviewRepository.reviewsFor(dormitoryId);
    notifyListeners();
  }
}
