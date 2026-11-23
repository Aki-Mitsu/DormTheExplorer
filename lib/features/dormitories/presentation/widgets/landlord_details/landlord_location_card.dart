import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';
import '../../../data/batangas_city_boundary.dart';
import 'landlord_detail_parts.dart';

class LandlordLocationCard extends StatelessWidget {
  const LandlordLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.mapController,
    required this.onPositionChanged,
    required this.onMapReady,
  });

  final double? latitude;
  final double? longitude;
  final String address;
  final MapController mapController;
  final void Function(MapCamera camera, bool hasGesture) onPositionChanged;
  final void Function(double latitude, double longitude) onMapReady;

  @override
  Widget build(BuildContext context) {
    final latitude = this.latitude;
    final longitude = this.longitude;

    return DetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailSectionTitle(
            icon: Icons.pin_drop_outlined,
            title: 'Property Location Pin',
          ),
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
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 15,
                    cameraConstraint: CameraConstraint.contain(
                      bounds: BatangasCityBoundary.mapBounds,
                    ),
                    onPositionChanged: onPositionChanged,
                    onMapReady: () => onMapReady(latitude, longitude),
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
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: BatangasCityBoundary.mapBoundsRing,
                          holePointsList: BatangasCityBoundary.polygons,
                          color: AppTheme.onSurface.withValues(alpha: 0.28),
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
          if (address.trim().isNotEmpty) ...[
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
                      address,
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
}
