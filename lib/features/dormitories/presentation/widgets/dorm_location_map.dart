import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_theme.dart';

class DormLocationMap extends StatelessWidget {
  const DormLocationMap({
    super.key,
    required this.dormLocation,
    required this.dormLabel,
    required this.routePoints,
    required this.destination,
    this.onMapTap,
    this.onDormMarkerTap,
  });

  final LatLng dormLocation;
  final String dormLabel;
  final List<LatLng> routePoints;
  final LatLng destination;
  final ValueChanged<LatLng>? onMapTap;
  final VoidCallback? onDormMarkerTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              key: ObjectKey(routePoints),
              options: MapOptions(
                initialCenter: routePoints.isEmpty
                    ? dormLocation
                    : routePoints[routePoints.length ~/ 2],
                initialZoom: 13,
                onTap: onMapTap == null
                    ? null
                    : (tapPosition, point) => onMapTap!(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dormtheexplorer.app.dorm_the_explorer',
                  maxNativeZoom: 19,
                ),
                if (routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: AppTheme.primaryContainer,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: dormLocation,
                      width: 52,
                      height: 58,
                      child: GestureDetector(
                        onTap: onDormMarkerTap,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryContainer,
                          size: 48,
                        ),
                      ),
                    ),
                    Marker(
                      point: destination,
                      width: 44,
                      height: 48,
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppTheme.secondary,
                        size: 34,
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
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 230),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppTheme.primaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dormLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
