import 'package:latlong2/latlong.dart';

class RouteDestination {
  const RouteDestination({
    required this.name,
    required this.address,
    required this.location,
  });

  final String name;
  final String address;
  final LatLng location;

  static const campuses = <RouteDestination>[
    RouteDestination(
      name: 'BatStateU Alangilan',
      address: 'Neptune Street, Alangilan, Batangas City',
      location: LatLng(13.78421, 121.07428),
    ),
    RouteDestination(
      name: 'BatStateU Pablo Borbon',
      address: 'Rizal Avenue Extension, Batangas City',
      location: LatLng(13.75514, 121.05305),
    ),
    RouteDestination(
      name: 'Lyceum of the Philippines University',
      address: 'Capitol Site, Batangas City',
      location: LatLng(13.76342, 121.06537),
    ),
  ];
}
