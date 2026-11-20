import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_theme.dart';

class DormLocationMap extends StatefulWidget {
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
  State<DormLocationMap> createState() => _DormLocationMapState();
}

class _DormLocationMapState extends State<DormLocationMap> {
  late final NetworkTileProvider _tileProvider = NetworkTileProvider(
    headers: {
      'User-Agent':
          'DormTheExplorer/1.0 (https://github.com/shirokase/Dorm-the-Explorer)',
    },
  );

  @override
  void dispose() {
    _tileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: [
                    widget.dormLocation,
                    widget.destination,
                    ...widget.routePoints,
                  ],
                  padding: const EdgeInsets.all(40),
                  maxZoom: 16,
                ),
                onTap: widget.onMapTap == null
                    ? null
                    : (tapPosition, point) => widget.onMapTap!(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: _tileProvider,
                  userAgentPackageName: 'dormtheexplorer.app.dorm_the_explorer',
                  maxNativeZoom: 19,
                  evictErrorTileStrategy:
                      EvictErrorTileStrategy.notVisibleRespectMargin,
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('OpenStreetMap tile failed: $error');
                  },
                ),
                if (widget.routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints,
                        strokeWidth: 4,
                        color: AppTheme.primaryContainer,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.dormLocation,
                      width: 52,
                      height: 58,
                      child: GestureDetector(
                        onTap: widget.onDormMarkerTap,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryContainer,
                          size: 48,
                        ),
                      ),
                    ),
                    Marker(
                      point: widget.destination,
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
                        widget.dormLabel,
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
