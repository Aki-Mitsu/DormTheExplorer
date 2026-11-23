import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/dorm_route.dart';
import '../../domain/route_destination.dart';
import 'campus_selection_bottom_sheet.dart';
import 'dorm_location_map.dart';

class DormDetailsLocationDirectionsSection extends StatelessWidget {
  const DormDetailsLocationDirectionsSection({
    super.key,
    required this.sectionKey,
    required this.hasLocation,
    required this.previewingLocation,
    required this.canEditLocation,
    required this.dormLocation,
    required this.dormName,
    required this.address,
    required this.monthlyRentLabel,
    required this.destination,
    required this.route,
    required this.isLoadingRoute,
    required this.routeError,
    required this.onDestinationChanged,
    required this.onLocationPicked,
    required this.onGetDirections,
    required this.onRetryRoute,
  });

  final Key sectionKey;
  final bool hasLocation;
  final bool previewingLocation;
  final bool canEditLocation;
  final LatLng dormLocation;
  final String dormName;
  final String address;
  final String monthlyRentLabel;
  final RouteDestination destination;
  final DormRoute? route;
  final bool isLoadingRoute;
  final Object? routeError;
  final ValueChanged<RouteDestination> onDestinationChanged;
  final ValueChanged<LatLng> onLocationPicked;
  final VoidCallback onGetDirections;
  final Future<void> Function() onRetryRoute;

  void _showPinDetails(BuildContext context) {
    final coordinates =
        '${dormLocation.latitude.toStringAsFixed(5)}, '
        '${dormLocation.longitude.toStringAsFixed(5)}';
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
              Text(dormName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                address.isEmpty ? 'Address not provided' : address,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                monthlyRentLabel,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: AppTheme.primaryContainer),
              ),
              if (canEditLocation)
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

  Widget _routeSummary(BuildContext context) {
    final route = this.route;
    if (isLoadingRoute) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (!hasLocation && !canEditLocation) {
      return const Text('Route unavailable until the dorm pin is saved.');
    }
    if (routeError != null) {
      return Row(
        children: [
          const Icon(Icons.route_outlined, color: AppTheme.outline),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Could not load route. Check your connection and retry.',
            ),
          ),
          IconButton(
            tooltip: 'Retry route',
            onPressed: onRetryRoute,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                color: AppTheme.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'From ${destination.name}',
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
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TravelTimeEstimate(
                icon: Icons.directions_walk_rounded,
                label: 'Walk ${route.walkingDurationLabel}',
              ),
              _TravelTimeEstimate(
                icon: Icons.directions_bike_rounded,
                label: 'Bike ${route.bikingDurationLabel}',
              ),
              _TravelTimeEstimate(
                icon: Icons.directions_car_rounded,
                label: 'Drive ${route.drivingDurationLabel}',
              ),
              _TravelTimeEstimate(
                icon: Icons.two_wheeler_rounded,
                label: 'Motorcycle ${route.motorcycleDurationLabel}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Walking and biking use typical speeds; driving and motorcycle use the OSRM road-route estimate.',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    key: sectionKey,
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
        CampusRouteDropdown(
          selectedCampus: destination,
          onChanged: onDestinationChanged,
        ),
        const SizedBox(height: 10),
        if (previewingLocation && !canEditLocation)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'The landlord has not saved an exact map location for this dorm yet.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.primaryDeep),
            ),
          ),
        if (hasLocation || canEditLocation) ...[
          DormLocationMap(
            dormLocation: dormLocation,
            dormLabel: dormName,
            routePoints: route?.geometry ?? const [],
            destination: destination.location,
            onMapTap: canEditLocation ? onLocationPicked : null,
            onDormMarkerTap: () => _showPinDetails(context),
          ),
          if (hasLocation)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onGetDirections,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Get directions'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: AppTheme.onPrimary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
        ] else
          _locationUnavailableCard(),
        if (canEditLocation)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tap the map to place the landlord pin. This preview is not saved until listing creation is ready.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 10),
        _routeSummary(context),
      ],
    ),
  );

  Widget _locationUnavailableCard() => Container(
    height: 220,
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 32, color: AppTheme.outline),
            SizedBox(height: 8),
            Text('Map unavailable until the dorm pin is saved.'),
          ],
        ),
      ),
    ),
  );
}

class _TravelTimeEstimate extends StatelessWidget {
  const _TravelTimeEstimate({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
