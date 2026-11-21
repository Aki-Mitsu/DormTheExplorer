import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import 'add_dormitory_screen.dart';
import 'widgets/dormitory_photo_viewer.dart';

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
  late Dormitory _dormitory;
  late StreamSubscription<Dormitory?> _dormitorySubscription;
  int _selectedPhoto = 0;
  bool _isUpdating = false;

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
            if (mounted) _showMessage('Could not refresh this listing: $error');
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

    try {
      await _repository.deleteDormitory(
        dormitoryId: _dormitory.id,
        landlordId: widget.userId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage('Could not delete listing: $error');
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
                  _photoGallery(),
                  const SizedBox(height: 12),
                  _availabilityCard(isAvailable),
                  const SizedBox(height: 12),
                  _overviewCard(),
                  const SizedBox(height: 12),
                  _descriptionCard(),
                  const SizedBox(height: 12),
                  _amenitiesCard(),
                  const SizedBox(height: 12),
                  _locationCard(),
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
                    onPressed: _isUpdating ? null : _deleteListing,
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

  Widget _photoGallery() {
    final photos = _dormitory.photoUrls;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: photos.isEmpty ? null : _openPhotoViewer,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: photos.isEmpty
                    ? Container(
                        color: AppTheme.surfaceContainer,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 48,
                          color: AppTheme.outline,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _photoController,
                            physics: const PageScrollPhysics(),
                            itemCount: photos.length,
                            onPageChanged: (index) =>
                                setState(() => _selectedPhoto = index),
                            itemBuilder: (context, index) => Image.network(
                              photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.surfaceContainer,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 38,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.inverseSurface.withValues(
                                    alpha: 0.82,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_selectedPhoto + 1} / ${photos.length} Photos',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppTheme.surfaceContainerLowest,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (photos.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => InkWell(
                  onTap: () {
                    _photoController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPhoto == index
                            ? AppTheme.primaryContainer
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.surfaceContainer,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _availabilityCard(bool isAvailable) {
    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppTheme.primaryFixed,
                child: const Icon(
                  Icons.toggle_on_rounded,
                  color: AppTheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability Status',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Manage room availability',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (_isUpdating)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: isAvailable,
                  onChanged: _toggleAvailability,
                  activeThumbColor: AppTheme.surfaceContainerLowest,
                  activeTrackColor: AppTheme.secondary,
                  inactiveThumbColor: AppTheme.surfaceContainerLowest,
                  inactiveTrackColor: AppTheme.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.secondaryContainer.withValues(alpha: 0.4)
                        : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isAvailable
                        ? 'Available (${_dormitory.availableSlots} Slots Vacant)'
                        : 'Full (0 Slots Vacant)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isAvailable
                          ? AppTheme.onSecondaryContainer
                          : AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isUpdating ? null : _chooseAvailableSlots,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Set slots'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Full dormitories remain visible to seekers and show as full.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _dormitory.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppTheme.primaryContainer,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _dormitory.address.isEmpty
                      ? 'Address not provided'
                      : _dormitory.address,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _metricTile(
                      label: 'MONTHLY RENT',
                      value: _formatPrice(_dormitory.monthlyPrice),
                      subtitle: 'per month / slot',
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _metricTile(
                      label: 'CAPACITY SLOTS',
                      value: '${_dormitory.availableSlots} Available',
                      subtitle: '${_dormitory.totalSlots} total occupancy',
                      color: _dormitory.availableSlots > 0
                          ? AppTheme.secondary
                          : AppTheme.error,
                    ),
                  ),
                  if (_dormitory.roomTypes.isNotEmpty)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _metricTile(
                        label: 'ROOM CONFIGURATIONS',
                        value: _dormitory.roomTypes.join(' • '),
                        subtitle: '',
                        color: AppTheme.onSurface,
                        icon: Icons.bed_outlined,
                      ),
                    ),

                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard() {
    final description = _dormitory.description.trim();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(Icons.description_outlined, 'About the Property'),
          const SizedBox(height: 8),
          Text(
            description.isEmpty
                ? 'No property description provided.'
                : description,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _amenitiesCard() {
    final selected = _dormitory.amenities.map(_canonicalAmenity).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Amenities Overview',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _amenityOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final (key, label, icon) = _amenityOptions[index];
            return _amenityTile(
              label: label,
              icon: icon,
              available: selected.contains(key),
            );
          },
        ),
      ],
    );
  }

  Widget _locationCard() {
    final latitude = _dormitory.latitude;
    final longitude = _dormitory.longitude;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(Icons.pin_drop_outlined, 'Property Location Pin'),
          const SizedBox(height: 10),
          if (latitude == null || longitude == null)
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      color: AppTheme.outline,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No map coordinates are saved for this listing.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'dormtheexplorer.app.dorm_the_explorer',
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 44,
                          height: 48,
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 44,
                            color: AppTheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_dormitory.address.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _dormitory.address,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppTheme.onSurface.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionTitle(IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 19, color: AppTheme.primaryContainer),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _metricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    IconData? icon,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 80),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (icon != null)
              Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ],
    ),
  );

  Widget _amenityTile({
    required String label,
    required IconData icon,
    required bool available,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: available ? AppTheme.secondary : AppTheme.outline,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
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

  String _canonicalAmenity(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return switch (normalized) {
      'wifi' || 'wififiber' => 'wifi',
      'owncr' || 'bathroom' => 'own_cr',
      'kitchen' || 'kitchenarea' => 'kitchen',
      'parking' || 'vehicleparking' => 'parking',
      'aircon' || 'airconditioning' => 'aircon',
      'laundry' || 'laundryarea' => 'laundry',
      _ => normalized,
    };
  }

  String _formatPrice(num price) {
    final grouped = price.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₱$grouped';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
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
