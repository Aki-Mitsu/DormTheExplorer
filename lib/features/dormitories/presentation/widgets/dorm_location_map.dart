import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_theme.dart';
import '../../data/batangas_city_boundary.dart';

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
  final MapController _mapController = MapController();
  bool _isReturningToCity = false;
  LatLng _lastValidMapCenter = const LatLng(13.7565, 121.0583);
  double _lastValidMapZoom = 15;

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
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
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
                cameraConstraint: CameraConstraint.contain(
                  bounds: BatangasCityBoundary.mapBounds,
                ),
                onPositionChanged: (camera, hasGesture) {
                  if (_isReturningToCity) return;
                  if (BatangasCityBoundary.contains(camera.center)) {
                    _lastValidMapCenter = camera.center;
                    _lastValidMapZoom = camera.zoom;
                    return;
                  }
                  if (!hasGesture) return;
                  _isReturningToCity = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _mapController.move(
                      _lastValidMapCenter,
                      _lastValidMapZoom,
                    );
                    _isReturningToCity = false;
                  });
                },
                onMapReady: () {
                  final camera = _mapController.camera;
                  if (BatangasCityBoundary.contains(camera.center)) {
                    _lastValidMapCenter = camera.center;
                    _lastValidMapZoom = camera.zoom;
                  } else {
                    final returnPoint =
                        BatangasCityBoundary.contains(widget.dormLocation)
                        ? widget.dormLocation
                        : const LatLng(13.7565, 121.0583);
                    _mapController.move(returnPoint, camera.zoom);
                  }
                },
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
