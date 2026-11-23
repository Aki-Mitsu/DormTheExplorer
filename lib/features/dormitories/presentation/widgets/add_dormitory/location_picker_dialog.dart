import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_theme.dart';
import '../../../data/batangas_city_boundary.dart';
import '../../../data/dorm_location_service.dart';

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({
    super.key,
    required this.initialLocation,
    required this.initialAddress,
    required this.locationService,
    required this.onMessage,
  });

  final LatLng initialLocation;
  final String initialAddress;
  final DormLocationService locationService;
  final ValueChanged<String> onMessage;

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final mapController = MapController();
  late LatLng selectedLocation;
  late String selectedAddress;
  bool selectionChanged = false;
  bool isLocating = false;
  bool isResolvingAddress = false;
  bool isReturningToCity = false;
  late LatLng lastValidMapCenter;
  late double lastValidMapZoom;
  String? locationMessage;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
    selectedAddress = widget.initialAddress;
    if (!widget.locationService.isWithinBatangasCity(selectedLocation)) {
      selectedLocation = const LatLng(13.7565, 121.0583);
      selectedAddress = '';
      selectionChanged = true;
    }
    if (selectedAddress.isEmpty) selectedAddress = '';
    lastValidMapCenter = selectedLocation;
    lastValidMapZoom = 15.0;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => isLocating = true);
    try {
      final location = await widget.locationService.getCurrentLocation();
      if (!mounted) return;
      if (!widget.locationService.isWithinBatangasCity(location)) {
        setState(
          () => locationMessage =
              'Your current location is outside Batangas City. '
              'Choose a pin within the outlined area.',
        );
        return;
      }

      lastValidMapCenter = location;
      lastValidMapZoom = 16;
      mapController.move(location, 16);
      setState(() {
        selectedLocation = location;
        selectedAddress = '';
        selectionChanged = true;
        locationMessage = null;
      });

      try {
        final address = await widget.locationService.reverseGeocode(location);
        if (!mounted) return;
        setState(() => selectedAddress = address ?? '');
        if (address == null && mounted) {
          widget.onMessage(
            'Location found. Enter the street address manually.',
          );
        }
      } catch (_) {
        if (mounted) {
          widget.onMessage(
            'Location found, but its address could not be looked up. '
            'Enter it manually.',
          );
        }
      }
    } on DormLocationException catch (error) {
      if (!mounted) return;
      if (error.issue == DormLocationIssue.servicesDisabled) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (promptContext) => AlertDialog(
            title: const Text('Turn on location'),
            content: const Text(
              'Enable your phone location services to use your current position.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(promptContext, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(promptContext, true),
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await widget.locationService.openLocationSettings();
        }
      } else if (error.issue ==
          DormLocationIssue.permissionDeniedForever) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (promptContext) => AlertDialog(
            title: const Text('Location permission needed'),
            content: const Text(
              'Allow location access in app settings, or keep placing the pin manually.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(promptContext, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(promptContext, true),
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await widget.locationService.openAppSettings();
        }
      } else if (mounted) {
        widget.onMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        widget.onMessage(
          'Could not get your current location. You can place the pin manually.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLocating = false);
      }
    }
  }

  Future<void> _confirmLocation() async {
    if (locationMessage != null) return;
    if (!widget.locationService.isWithinBatangasCity(selectedLocation)) {
      setState(
        () => locationMessage =
            'Choose a pin within Batangas City to continue.',
      );
      return;
    }
    if (!selectionChanged && selectedAddress.isNotEmpty) {
      Navigator.pop(
        context,
        (selectedLocation, selectedAddress),
      );
      return;
    }

    setState(() {
      isResolvingAddress = true;
      locationMessage = null;
    });
    String? address;
    try {
      address = await widget.locationService.reverseGeocode(selectedLocation);
    } catch (_) {
      address = null;
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      (selectedLocation, address),
    );
    if ((address == null || address.isEmpty) && mounted) {
      widget.onMessage(
        'Pin saved within Batangas City. Enter the complete address manually.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose dormitory location',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a point inside the Batangas City boundary, or use your current location.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isLocating || isResolvingAddress
                    ? null
                    : _useCurrentLocation,
                icon: isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  isLocating
                      ? 'Finding your location…'
                      : 'Use my current location',
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.40,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: selectedLocation,
                      initialZoom: 15,
                      cameraConstraint: CameraConstraint.contain(
                        bounds: BatangasCityBoundary.mapBounds,
                      ),
                      onPositionChanged: (camera, hasGesture) {
                        if (isReturningToCity) return;
                        if (widget.locationService.isWithinBatangasCity(
                          camera.center,
                        )) {
                          lastValidMapCenter = camera.center;
                          lastValidMapZoom = camera.zoom;
                          return;
                        }
                        if (!hasGesture) return;
                        isReturningToCity = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          mapController.move(
                            lastValidMapCenter,
                            lastValidMapZoom,
                          );
                          isReturningToCity = false;
                        });
                      },
                      onTap: (tapPosition, point) {
                        if (!widget.locationService
                            .isWithinBatangasCity(point)) {
                          setState(
                            () => locationMessage =
                                'That point is outside Batangas City. '
                                'Choose a point inside the outlined area.',
                          );
                          return;
                        }
                        setState(() {
                          selectedLocation = point;
                          selectedAddress = '';
                          selectionChanged = true;
                          locationMessage = null;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        tileProvider: NetworkTileProvider(
                          cachingProvider: const DisabledMapCachingProvider(),
                        ),
                        userAgentPackageName:
                            'dormtheexplorer.app.dorm_the_explorer',
                        maxNativeZoom: 19,
                      ),
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: BatangasCityBoundary.mapBoundsRing,
                            holePointsList: BatangasCityBoundary.polygons,
                            color: AppTheme.onSurface.withValues(
                              alpha: 0.28,
                            ),
                            borderStrokeWidth: 0,
                            disableHolesBorder: true,
                          ),
                          for (final boundary in BatangasCityBoundary.polygons)
                            Polygon(
                              points: boundary,
                              color: const Color(0x00000000),
                              borderColor: AppTheme.primaryContainer,
                              borderStrokeWidth: 2,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedLocation,
                            width: 48,
                            height: 52,
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 46,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      RichAttributionWidget(
                        alignment: AttributionAlignment.bottomRight,
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${selectedLocation.latitude.toStringAsFixed(5)}, '
                '${selectedLocation.longitude.toStringAsFixed(5)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (locationMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  locationMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: isLocating || isResolvingAddress
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: isLocating || isResolvingAddress
                          ? null
                          : _confirmLocation,
                      child: isResolvingAddress
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.onPrimary,
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Use this location'),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
