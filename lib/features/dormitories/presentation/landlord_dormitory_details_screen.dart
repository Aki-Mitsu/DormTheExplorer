import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app_notice.dart';
import '../../../theme/app_theme.dart';
import '../data/batangas_city_boundary.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import 'add_dormitory_screen.dart';
import 'widgets/dormitory_photo_viewer.dart';
import 'widgets/landlord_details/landlord_detail_cards.dart';
import 'widgets/landlord_details/landlord_location_card.dart';
import 'widgets/landlord_details/landlord_photo_gallery.dart';

class LandlordDormitoryDetailsScreen extends StatefulWidget {
  const LandlordDormitoryDetailsScreen({
    super.key,
    required this.dormitory,
    required this.userId,
  });

  final Dormitory dormitory;
  final String userId;

  @override
  State<LandlordDormitoryDetailsScreen> createState() =>
      _LandlordDormitoryDetailsScreenState();
}

class _LandlordDormitoryDetailsScreenState
    extends State<LandlordDormitoryDetailsScreen> {
  static const List<(String, String, IconData)> _amenityOptions = [
    ('wifi', 'WiFi', Icons.wifi_rounded),
    ('own_cr', 'Own CR', Icons.bathtub_outlined),
    ('aircon', 'Air Conditioning', Icons.ac_unit_rounded),
    ('kitchen', 'Kitchen', Icons.countertops_outlined),
    ('laundry', 'Laundry', Icons.local_laundry_service_outlined),
    ('parking', 'Parking', Icons.local_parking_rounded),
  ];

  final DormitoryRepository _repository = DormitoryRepository();
  final PageController _photoController = PageController();
  final MapController _locationMapController = MapController();
  bool _isReturningLocationMap = false;
  LatLng _lastValidLocationMapCenter = const LatLng(13.7565, 121.0583);
  double _lastValidLocationMapZoom = 15;
  late Dormitory _dormitory;
  late StreamSubscription<Dormitory?> _dormitorySubscription;
  int _selectedPhoto = 0;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _dormitory = widget.dormitory;
    _dormitorySubscription = _repository
        .watchDormitory(widget.dormitory.id)
        .listen(
          (dormitory) {
            if (!mounted || dormitory == null) return;
            setState(() => _dormitory = dormitory);
          },
          onError: (Object error) {
            if (mounted && !_isDeleting) {
              _showMessage('Could not refresh this listing: $error');
            }
          },
        );
  }

  @override
  void dispose() {
    unawaited(_dormitorySubscription.cancel());
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _openEditForm() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddDormitoryScreen(
          userId: widget.userId,
          existingDormitory: _dormitory,
        ),
      ),
    );
  }

  Future<void> _toggleAvailability(bool isAvailable) async {
    final nextAvailableSlots = isAvailable ? _dormitory.totalSlots : 0;
    await _saveAvailableSlots(nextAvailableSlots);
  }

  Future<void> _chooseAvailableSlots() async {
    final availableSlots = await showDialog<int>(
      context: context,
      builder: (_) => _AvailableSlotsDialog(
        currentSlots: _dormitory.availableSlots,
        totalSlots: _dormitory.totalSlots,
      ),
    );
    if (!mounted || availableSlots == null) return;
    await _saveAvailableSlots(availableSlots);
  }

  Future<void> _saveAvailableSlots(int availableSlots) async {
    if (availableSlots < 0 || availableSlots > _dormitory.totalSlots) {
      _showMessage('Available slots must be between 0 and total capacity.');
      return;
    }
    if (_isUpdating) return;

    setState(() => _isUpdating = true);
    try {
      await _repository.setAvailability(
        dormitoryId: _dormitory.id,
        landlordId: widget.userId,
        availableSlots: availableSlots,
      );
      if (mounted) {
        _showMessage(
          availableSlots == 0
              ? 'Dormitory marked as full.'
              : 'Availability updated to $availableSlots slots.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage('Could not update availability: $error');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteListing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        iconColor: AppTheme.error,
        iconPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: const Text('Delete Dormitory Listing?'),
        titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        content: Text(
          'Are you sure you want to delete "${_dormitory.name}"? '
          'This action cannot be undone.',
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppTheme.error,
                    foregroundColor: AppTheme.onError,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _repository.deleteDormitory(
        dormitoryId: _dormitory.id,
        landlordId: widget.userId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showMessage('Could not delete listing: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _dormitory.status.toLowerCase() == 'approved';
    final isAvailable = _dormitory.availableSlots > 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to My Listings',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          'Dormitory Details',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _managementStatus(
                    isApproved: isApproved,
                    isAvailable: isAvailable,
                  ),
                  const SizedBox(height: 12),
                  LandlordPhotoGallery(
                    photoUrls: _dormitory.photoUrls,
                    photoController: _photoController,
                    selectedPhoto: _selectedPhoto,
                    onPageChanged: (index) =>
                        setState(() => _selectedPhoto = index),
                    onOpenPhotoViewer: _openPhotoViewer,
                  ),
                  const SizedBox(height: 12),
                  LandlordAvailabilityCard(
                    isAvailable: isAvailable,
                    isUpdating: _isUpdating,
                    availableSlots: _dormitory.availableSlots,
                    onToggleAvailability: _toggleAvailability,
                    onChooseAvailableSlots: _chooseAvailableSlots,
                  ),
                  const SizedBox(height: 12),
                  LandlordOverviewCard(dormitory: _dormitory),
                  const SizedBox(height: 12),
                  LandlordDescriptionCard(description: _dormitory.description),
                  const SizedBox(height: 12),
                  LandlordAmenitiesCard(
                    amenities: _dormitory.amenities,
                    amenityOptions: _amenityOptions,
                  ),
                  const SizedBox(height: 12),
                  LandlordLocationCard(
                    latitude: _dormitory.latitude,
                    longitude: _dormitory.longitude,
                    address: _dormitory.address,
                    mapController: _locationMapController,
                    onPositionChanged: _onLocationMapPositionChanged,
                    onMapReady: _onLocationMapReady,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openEditForm,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit Property Details'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      elevation: 2,
                      shadowColor: AppTheme.primaryContainer.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isUpdating || _isDeleting ? null : _deleteListing,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Dormitory Listing'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onErrorContainer,
                      backgroundColor: AppTheme.errorContainer,
                      side: BorderSide.none,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _managementStatus({
    required bool isApproved,
    required bool isAvailable,
  }) {
    final label = !isApproved
        ? _dormitory.status.toUpperCase()
        : isAvailable
        ? 'ACTIVE (AVAILABLE)'
        : 'FULL (0 SLOTS)';
    final color = !isApproved
        ? AppTheme.tertiaryContainer
        : isAvailable
        ? AppTheme.secondary
        : AppTheme.onSurfaceVariant;

    return Row(
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 18,
          color: AppTheme.primaryContainer,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'LANDLORD MANAGEMENT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable
                ? AppTheme.secondaryContainer.withValues(alpha: 0.35)
                : AppTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Future<void> _openPhotoViewer() => showDormitoryPhotoViewer(
    context,
    photoUrls: _dormitory.photoUrls,
    initialIndex: _selectedPhoto,
  );

  void _onLocationMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (_isReturningLocationMap) return;
    if (BatangasCityBoundary.contains(camera.center)) {
      _lastValidLocationMapCenter = camera.center;
      _lastValidLocationMapZoom = camera.zoom;
      return;
    }
    if (!hasGesture) return;
    _isReturningLocationMap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _locationMapController.move(
        _lastValidLocationMapCenter,
        _lastValidLocationMapZoom,
      );
      _isReturningLocationMap = false;
    });
  }

  void _onLocationMapReady(double latitude, double longitude) {
    final camera = _locationMapController.camera;
    if (BatangasCityBoundary.contains(camera.center)) {
      _lastValidLocationMapCenter = camera.center;
      _lastValidLocationMapZoom = camera.zoom;
    } else {
      _locationMapController.move(
        LatLng(latitude, longitude),
        camera.zoom,
      );
    }
  }

  void _showMessage(String message) => AppNotice.show(context, message);
}

class _AvailableSlotsDialog extends StatefulWidget {
  const _AvailableSlotsDialog({
    required this.currentSlots,
    required this.totalSlots,
  });

  final int currentSlots;
  final int totalSlots;

  @override
  State<_AvailableSlotsDialog> createState() => _AvailableSlotsDialogState();
}

class _AvailableSlotsDialogState extends State<_AvailableSlotsDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentSlots.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0 || value > widget.totalSlots) return;

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available Slots'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Available slots',
          helperText: 'Enter 0 to mark this dormitory as full.',
          suffixText: '/ ${widget.totalSlots}',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
