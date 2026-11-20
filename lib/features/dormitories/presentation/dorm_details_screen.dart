import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../data/dorm_review_repository.dart';
import '../data/osrm_routing_service.dart';
import '../domain/dorm_review.dart';
import '../domain/dorm_route.dart';
import '../domain/dormitory.dart';
import '../domain/route_destination.dart';
import 'dorm_details_view_model.dart';
import 'widgets/dorm_location_map.dart';

class DormDetailsScreen extends StatefulWidget {
  const DormDetailsScreen({
    super.key,
    required this.dormitory,
    this.canEditLocation = false,
    this.canReview = true,
  });

  final Dormitory dormitory;
  final bool canEditLocation;
  final bool canReview;

  @override
  State<DormDetailsScreen> createState() => _DormDetailsScreenState();
}

class _DormDetailsScreenState extends State<DormDetailsScreen> {
  static const _previewLocation = LatLng(13.7661, 121.0600);

  late final DormDetailsViewModel _viewModel;
  final _scrollController = ScrollController();
  final _reviewController = TextEditingController();
  final _mapKey = GlobalKey();
  final _pageController = PageController();
  late LatLng _dormLocation;
  RouteDestination _destination = RouteDestination.campuses.first;
  int _photoIndex = 0;
  int _selectedRating = 5;
  bool _bookmarked = false;
  bool _submittingReview = false;

  bool get _hasLocation =>
      widget.dormitory.latitude != null &&
      widget.dormitory.longitude != null;
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

  Future<void> _loadRoute() => _viewModel.loadRoute(
    origin: _dormLocation,
    destination: _destination,
  );

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
        title: const Text('Dorm Details'),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
            icon: Icon(
              _bookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _bookmarked ? AppTheme.primaryContainer : null,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 792 ? 760.0 : constraints.maxWidth;
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
                    _photoGallery(),
                    _overview(),
                    _roomTypes(),
                    _amenities(),
                    _description(),
                    _reportButton(),
                    _landlordContact(),
                    _locationAndRoute(),
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

  Widget _photoGallery() {
    final count = widget.dormitory.photoUrls.isEmpty
        ? 3
        : widget.dormitory.photoUrls.length;
    final proximity = widget.dormitory.proximityLabel?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: count,
                    onPageChanged: (page) => setState(() => _photoIndex = page),
                    itemBuilder: (context, index) {
                      if (widget.dormitory.photoUrls.isEmpty) {
                        return const _PhotoPlaceholder(label: 'Dorm photo');
                      }
                      return Image.network(
                        widget.dormitory.photoUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const _PhotoPlaceholder(label: 'Photo unavailable'),
                      );
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0x77000000), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _Tag(
                      icon: Icons.directions_walk_rounded,
                      label: proximity?.isNotEmpty == true
                          ? proximity!
                          : _previewingLocation
                          ? 'Sample location'
                          : 'Dorm location',
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _Tag(
                      label: '${_photoIndex + 1} / $count',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(count < 3 ? count : 3, (index) {
              final urls = widget.dormitory.photoUrls;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: urls.isEmpty
                            ? const _PhotoPlaceholder(
                                label: 'Placeholder',
                                compact: true,
                              )
                            : Image.network(
                                urls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const _PhotoPlaceholder(
                                      label: 'Photo',
                                      compact: true,
                                    ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _overview() {
    final dorm = widget.dormitory;
    final address = dorm.address.trim();
    final reviews = _viewModel.reviews;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _dormName,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: AppTheme.primaryContainer),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address.isEmpty ? 'Address will be added by the landlord' : address,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppTheme.tertiaryAccent, size: 22),
                const SizedBox(width: 5),
                Text(
                  _viewModel.averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '(${reviews.length} student reviews)',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY RENT',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dorm.monthlyPrice > 0
                            ? '${_formatPrice(dorm.monthlyPrice)} / month'
                            : 'Price not provided',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dorm.utilitiesIncluded
                            ? '✓ Water & electricity included'
                            : 'Utility details not provided',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: dorm.utilitiesIncluded
                              ? AppTheme.secondary
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _AvailabilityBadge(
                    available: dorm.availableSlots,
                    total: dorm.totalSlots,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomTypes() => _section(
    'Room Types',
    widget.dormitory.roomTypes.isEmpty
        ? const _EmptyNote(
            icon: Icons.bed_outlined,
            text: 'Room options will appear when the listing is added.',
          )
        : Wrap(
            spacing: 8,
            children: widget.dormitory.roomTypes
                .map((room) => Chip(
                      avatar: const Icon(Icons.bed_outlined, size: 17),
                      label: Text(room),
                      backgroundColor: AppTheme.surfaceContainerLow,
                    ))
                .toList(growable: false),
          ),
  );

  Widget _amenities() {
    const options = <(String, IconData)>[
      ('WiFi', Icons.wifi_rounded),
      ('Own CR', Icons.bathtub_outlined),
      ('Air Conditioning', Icons.ac_unit_rounded),
      ('Kitchen', Icons.countertops_outlined),
      ('Laundry', Icons.local_laundry_service_outlined),
      ('Parking', Icons.local_parking_rounded),
    ];
    final amenities =
        widget.dormitory.amenities.map((value) => value.toLowerCase()).toSet();

    return _section(
      'Amenities Overview',
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 62,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final (name, icon) = options[index];
          final available = amenities.contains(name.toLowerCase());
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19,
                    color: available ? AppTheme.secondary : AppTheme.outline),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: available
                          ? AppTheme.onSurface
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  available
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 17,
                  color: available ? AppTheme.secondary : AppTheme.outline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _description() {
    final description = widget.dormitory.description.trim();
    return _section(
      'About $_dormName',
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          description.isEmpty
              ? 'The landlord has not added a description yet.'
              : description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ),
    );
  }

  Widget _reportButton() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Center(
      child: OutlinedButton.icon(
        onPressed: () => _showMessage(
          'Listing reports will be connected in a later release.',
        ),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: const Text('Report Listing'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          foregroundColor: AppTheme.onSurfaceVariant,
        ),
      ),
    ),
  );

  Widget _landlordContact() {
    final name = widget.dormitory.landlordName?.trim();
    final phone = widget.dormitory.landlordPhone?.trim();
    return _section(
      'Landlord Contact',
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.surfaceContainer,
              child: Icon(Icons.person_rounded, color: AppTheme.outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name?.isNotEmpty == true ? name! : 'Landlord name pending',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Property owner',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone?.isNotEmpty == true
                        ? phone!
                        : 'Contact number not provided',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.primaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationAndRoute() {
    final route = _viewModel.route;
    return Padding(
      key: _mapKey,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Campus Distance & Location',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<RouteDestination>(
            initialValue: _destination,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Route to',
              prefixIcon: Icon(Icons.school_outlined),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: RouteDestination.campuses
                .map((campus) => DropdownMenuItem(
                      value: campus,
                      child: Text(campus.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _destination = value);
              unawaited(_loadRoute());
            },
          ),
          const SizedBox(height: 10),
          if (_previewingLocation)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Preview route only: this dorm does not have saved coordinates yet.',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppTheme.primaryDeep),
              ),
            ),
          DormLocationMap(
            dormLocation: _dormLocation,
            dormLabel: _dormName,
            routePoints: route?.geometry ?? const [],
            destination: _destination.location,
            onMapTap: widget.canEditLocation ? _selectMapPin : null,
            onDormMarkerTap: _showPinDetails,
          ),
          if (widget.canEditLocation)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tap the map to place the landlord pin. This preview is not saved until listing creation is ready.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 10),
          _routeSummary(route),
        ],
      ),
    );
  }

  Widget _routeSummary(DormRoute? route) {
    if (_viewModel.isLoadingRoute) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_viewModel.routeError != null) {
      return Row(
        children: [
          const Icon(Icons.route_outlined, color: AppTheme.outline),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Could not load route. Check your connection and retry.'),
          ),
          IconButton(
            tooltip: 'Retry route',
            onPressed: _loadRoute,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      );
    }
    if (route == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.alt_route_rounded, color: AppTheme.primaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'To ${_destination.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Text(
            route.distanceLabel,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Text(
            route.durationLabel,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _reviewsSection() {
    final reviews = _viewModel.reviews;
    return _section(
      'Reviews',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canReview) _reviewComposer(),
          for (final review in reviews) _ReviewCard(review: review),
        ],
      ),
      trailing: Text(
        '${reviews.length} reviews',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppTheme.onSurfaceVariant),
      ),
    );
  }

  Widget _reviewComposer() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Write a review',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => IconButton(
              onPressed: () => setState(() => _selectedRating = index + 1),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              tooltip: '${index + 1} stars',
              icon: Icon(
                index < _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppTheme.tertiaryAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Share what future students should know...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _submittingReview ? null : _submitReview,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: _submittingReview
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: const Text('Post Review'),
          ),
        ),
      ],
    ),
  );

  Future<void> _submitReview() async {
    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      _showMessage('Write a comment before posting your review.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sign in to post a review.');
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
          _showMessage('Add your name to your profile before posting a review.');
        }
        return;
      }

      await _viewModel.submitReview(
        authorName: authorName,
        authorPhotoUrl: user.photoURL,
        rating: _selectedRating,
        comment: comment,
      );
      _reviewController.clear();
      if (mounted) _showMessage('Review posted successfully.');
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Could not load your profile name.');
      }
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  Widget _contactBar() {
    final phone = widget.dormitory.landlordPhone?.trim();
    final canContact = phone?.isNotEmpty == true;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryContainer.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: canContact ? () => _launchContact('tel', phone!) : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: canContact ? () => _launchContact('sms', phone!) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppTheme.surfaceContainer,
                  foregroundColor: AppTheme.onSurface,
                ),
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: const Text('SMS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _scrollToMap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppTheme.secondaryContainer,
                  foregroundColor: AppTheme.onSecondaryContainer,
                ),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Future<void> _selectMapPin(LatLng point) async {
    setState(() => _dormLocation = point);
    await _loadRoute();
  }

  void _showPinDetails() {
    final address = widget.dormitory.address.trim();
    final coordinates =
        '${_dormLocation.latitude.toStringAsFixed(5)}, '
        '${_dormLocation.longitude.toStringAsFixed(5)}';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dormName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                address.isEmpty ? 'Address not provided' : address,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                widget.dormitory.monthlyPrice > 0
                    ? '${_formatPrice(widget.dormitory.monthlyPrice)} / month'
                    : 'Monthly price not provided',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: AppTheme.primaryContainer),
              ),
              if (widget.canEditLocation)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Pin coordinates: $coordinates',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPrice(num price) {
    final grouped = price.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₱$grouped';
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.surfaceContainerHigh,
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.apartment_rounded,
            size: compact ? 23 : 58, color: AppTheme.outline),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.primaryContainer, size: 15),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppTheme.onSurface),
        ),
      ],
    ),
  );
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.available, required this.total});

  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    final full = total > 0 && available <= 0;
    final label = total <= 0
        ? 'Availability pending'
        : full
        ? 'Full • $total slots'
        : '$available available / $total slots';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: full ? AppTheme.errorContainer : AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: full
              ? AppTheme.onErrorContainer
              : AppTheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final DormReview review;

  @override
  Widget build(BuildContext context) {
    final trimmedName = review.authorName.trim();
    final initials = trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase();
    final photoUrl = review.authorPhotoUrl?.trim();

    return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primaryFixed,
              child: photoUrl == null || photoUrl.isEmpty
                  ? _avatarInitials(initials)
                  : ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _avatarInitials(initials),
                      ),
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.authorName,
                      style: Theme.of(context).textTheme.labelMedium),
                  Text(
                    review.authorSubtitle,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppTheme.tertiaryAccent,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          review.comment,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          review.stayLabel,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    ),
    );
  }

  Widget _avatarInitials(String initials) => Text(
    initials,
    style: const TextStyle(
      color: AppTheme.primaryContainer,
      fontWeight: FontWeight.w700,
    ),
  );
}
