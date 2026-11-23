import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_notice.dart';
import '../../../core/formatters.dart';
import '../../../theme/app_theme.dart';
import '../data/dorm_listing_report_repository.dart';
import '../data/dorm_review_repository.dart';
import '../data/osrm_routing_service.dart';
import '../domain/dorm_review.dart';
import '../domain/dormitory.dart';
import '../domain/route_destination.dart';
import 'dorm_details_view_model.dart';
import 'widgets/dorm_details_photo_gallery.dart';
import 'widgets/dorm_details_info_section.dart';
import 'widgets/dorm_details_amenities_section.dart';
import 'widgets/dorm_details_description_section.dart';
import 'widgets/dorm_room_types_section.dart';
import 'widgets/dorm_details_location_directions_section.dart';
import 'widgets/dorm_reviews_section.dart';
import 'widgets/dorm_report_button.dart';
import 'widgets/dorm_listing_report_dialog.dart';
import 'widgets/dorm_contact_sections.dart';
import 'widgets/dormitory_photo_viewer.dart';

class DormDetailsScreen extends StatefulWidget {
  const DormDetailsScreen({
    super.key,
    required this.dormitory,
    this.canEditLocation = false,
    this.canReview = true,
    this.canBookmark = true,
    this.canReport = true,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  final Dormitory dormitory;
  final bool canEditLocation;
  final bool canReview;
  final bool canBookmark;
  final bool canReport;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  @override
  State<DormDetailsScreen> createState() => _DormDetailsScreenState();
}

class _DormDetailsScreenState extends State<DormDetailsScreen> {
  static const _previewLocation = LatLng(13.7661, 121.0600);

  late final DormDetailsViewModel _viewModel;
  final DormListingReportRepository _reportRepository =
      FirestoreDormListingReportRepository();
  final _scrollController = ScrollController();
  final _reviewController = TextEditingController();
  final _mapKey = GlobalKey();
  final _pageController = PageController();
  late LatLng _dormLocation;
  RouteDestination _destination = RouteDestination.campuses.first;
  int _photoIndex = 0;
  int _selectedRating = 0;
  bool _bookmarked = false;
  bool _submittingReview = false;
  bool _submittingReport = false;
  String? _reviewSuccessMessage;

  bool get _hasLocation =>
      widget.dormitory.latitude != null && widget.dormitory.longitude != null;
  bool get _previewingLocation => !_hasLocation;

  String get _dormName {
    final name = widget.dormitory.name.trim();
    return name.isEmpty || name == 'Untitled dormitory'
        ? 'Dorm name coming soon'
        : name;
  }

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isFavorite;
    _dormLocation = _hasLocation
        ? LatLng(widget.dormitory.latitude!, widget.dormitory.longitude!)
        : _previewLocation;
    _viewModel = DormDetailsViewModel(
      dormitoryId: widget.dormitory.id,
      reviewRepository: FirestoreDormReviewRepository(),
      routingService: OsrmRoutingService(),
    )..addListener(_onViewModelChanged);
    unawaited(_loadRoute());
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRoute() {
    if (!_hasLocation && !widget.canEditLocation) return Future<void>.value();
    return _viewModel.loadRoute(
      origin: _destination.location,
      destination: _dormLocation,
    );
  }

  Future<void> _openGoogleMapsDirections() async {
    final destination =
        '${_dormLocation.latitude},${_dormLocation.longitude}';
    final directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    final opened = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      AppNotice.show(context, 'Could not open Google Maps.');
    }
  }


  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    _scrollController.dispose();
    _reviewController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Dorm Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (widget.canBookmark)
            IconButton(
              tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
              onPressed: () {
                final isFavorite = !_bookmarked;
                setState(() => _bookmarked = isFavorite);
                widget.onFavoriteChanged?.call(isFavorite);
              },
              icon: Icon(
                _bookmarked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _bookmarked ? AppTheme.primaryContainer : null,
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 792
              ? 760.0
              : constraints.maxWidth;
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 20),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DormDetailsPhotoGallery(
                      photoUrls: widget.dormitory.photoUrls,
                      pageController: _pageController,
                      photoIndex: _photoIndex,
                      onPageChanged: (page) =>
                          setState(() => _photoIndex = page),
                      onOpenPhotoViewer: _openPhotoViewer,
                    ),
                    DormDetailsInfoSection(
                      dormitory: widget.dormitory,
                      dormName: _dormName,
                      monthlyRentLabel: widget.dormitory.monthlyPrice > 0
                          ? '${formatPeso(widget.dormitory.monthlyPrice)} / month'
                          : 'Price not provided',
                    ),
                    DormRoomTypesSection(
                      roomTypes: DormRoomType.currentLabels(
                        widget.dormitory.roomTypes,
                      ),
                    ),
                    DormDetailsAmenitiesSection(
                      amenities: widget.dormitory.amenities,
                    ),
                    DormDetailsDescriptionSection(
                      dormName: _dormName,
                      description: widget.dormitory.description,
                    ),
                    _reportButton(),
                    _landlordContact(),
                    DormDetailsLocationDirectionsSection(
        sectionKey: _mapKey,
        hasLocation: _hasLocation,
        previewingLocation: _previewingLocation,
        canEditLocation: widget.canEditLocation,
        dormLocation: _dormLocation,
        dormName: _dormName,
        address: widget.dormitory.address.trim(),
        monthlyRentLabel: widget.dormitory.monthlyPrice > 0
            ? '${formatPeso(widget.dormitory.monthlyPrice)} / month'
            : 'Monthly price not provided',
        destination: _destination,
        route: _viewModel.route,
        isLoadingRoute: _viewModel.isLoadingRoute,
        routeError: _viewModel.routeError,
        onDestinationChanged: (campus) {
          if (campus == _destination) return;
          setState(() => _destination = campus);
          unawaited(_loadRoute());
        },
        onLocationPicked: _selectMapPin,
        onGetDirections: _openGoogleMapsDirections,
        onRetryRoute: _loadRoute,
      ),
                    _reviewsSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _contactBar(),
    );
  }

  Future<void> _openPhotoViewer() => showDormitoryPhotoViewer(
    context,
    photoUrls: widget.dormitory.photoUrls,
    initialIndex: _photoIndex,
  );

  Widget _reportButton() => widget.canReport
      ? DormReportButton(
          isSubmitting: _submittingReport,
          onPressed: _reportListing,
        )
      : const SizedBox.shrink();

  Future<void> _reportListing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sign in as a seeker to report this listing.');
      return;
    }

    final submission = await showDialog<DormListingReportSubmission>(
      context: context,
      builder: (_) => const DormListingReportDialog(),
    );
    if (!mounted || submission == null) return;

    setState(() => _submittingReport = true);
    try {
      await _reportRepository.submitReport(
        dormitoryId: widget.dormitory.id,
        reporterId: user.uid,
        reason: submission.reason,
        details: submission.details,
      );
      if (mounted) _showMessage('Report submitted. Thank you for letting us know.');
    } on StateError catch (error) {
      if (mounted) _showMessage(error.message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      if (error.code == 'permission-denied') {
        _showMessage(
          'Could not submit the report. Check that the latest Firestore rules '
          'are published, then try again.',
        );
      } else {
        _showMessage(error.message ?? 'Could not submit the report.');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not submit the report: $error');
    } finally {
      if (mounted) setState(() => _submittingReport = false);
    }
  }

  Widget _landlordContact() => DormLandlordContactSection(
    name: widget.dormitory.landlordName?.trim(),
    phone: widget.dormitory.landlordPhone?.trim(),
    photoUrl: widget.dormitory.landlordPhotoUrl?.trim(),
  );

  Widget _reviewsSection() => DormReviewsSection(
    reviews: _viewModel.reviews,
    averageRating: _viewModel.averageRating,
    canReview: widget.canReview,
    hasReviewed: _hasReviewed(_viewModel.reviews),
    reviewController: _reviewController,
    selectedRating: _selectedRating,
    isSubmittingReview: _submittingReview,
    successMessage: _reviewSuccessMessage,
    onRatingChanged: (rating) => setState(() => _selectedRating = rating),
    onSubmitReview: _submitReview,
    onDismissSuccess: () {
      if (mounted) setState(() => _reviewSuccessMessage = null);
    },
  );

  bool _hasReviewed(
    List<DormReview> reviews, {
    String? userId,
    String? authorName,
    String? authorPhotoUrl,
  }) {
    userId ??= FirebaseAuth.instance.currentUser?.uid;
    final normalizedName = authorName?.trim().toLowerCase();
    return reviews.any((review) {
      if (userId != null && review.authorUid == userId) return true;
      return review.authorUid == null &&
          normalizedName?.isNotEmpty == true &&
          review.authorName.trim().toLowerCase() == normalizedName &&
          review.authorPhotoUrl == authorPhotoUrl;
    });
  }



  Future<void> _submitReview() async {
    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      _showMessage('Write a comment before posting your review.');
      return;
    }
    if (_selectedRating == 0) {
      _showMessage('Select a star rating before posting your review.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sign in to post a review.');
      return;
    }
    if (_hasReviewed(_viewModel.reviews)) {
      _showMessage('You have already reviewed this dormitory.');
      return;
    }

    setState(() => _submittingReview = true);
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final profileName = (profile.data()?['fullName'] as String?)?.trim();
      final displayName = user.displayName?.trim();
      final authorName = profileName?.isNotEmpty == true
          ? profileName!
          : displayName;

      if (authorName == null || authorName.isEmpty) {
        if (mounted) {
          _showMessage(
            'Add your name to your profile before posting a review.',
          );
        }
        return;
      }
      if (_hasReviewed(
        _viewModel.reviews,
        userId: user.uid,
        authorName: authorName,
        authorPhotoUrl: user.photoURL,
      )) {
        if (mounted) {
          _showMessage('You have already reviewed this dormitory.');
        }
        return;
      }

      await _viewModel.submitReview(
        authorUid: user.uid,
        authorName: authorName,
        authorPhotoUrl: user.photoURL,
        rating: _selectedRating,
        comment: comment,
      );
      _reviewController.clear();
      if (mounted) {
        setState(() => _reviewSuccessMessage = 'Review posted successfully.');
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Could not load your profile name.');
      }
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  Widget _contactBar() => DormContactBar(
    phone: widget.dormitory.landlordPhone?.trim(),
    onLaunchContact: _launchContact,
    onShowRoute: _scrollToMap,
  );

  Future<void> _selectMapPin(LatLng point) async {
    setState(() => _dormLocation = point);
    await _loadRoute();
  }

  Future<void> _scrollToMap() async {
    final target = _mapKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  Future<void> _launchContact(String scheme, String phone) async {
    if (!await launchUrl(Uri(scheme: scheme, path: phone))) {
      _showMessage('Unable to open the phone app on this device.');
    }
  }

  void _showMessage(String message) => AppNotice.show(context, message);
}