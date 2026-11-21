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
    RouteDestination(
      name: 'University of Batangas',
      address: 'Hilltop Road, Kumintang Ibaba, Batangas City',
      location: LatLng(13.7639389, 121.0597917),
    ),
    RouteDestination(
      name: 'Golden Gate Colleges',
      address: 'Batangas City',
      location: LatLng(13.7570253, 121.0606075),
    ),
    RouteDestination(
      name: 'St. Bridget College',
      address: 'Batangas City',
      location: LatLng(13.7529481, 121.0584424),
    ),
    RouteDestination(
      name: 'STI College - Batangas',
      address: 'Batangas City',
      location: LatLng(13.7709325, 121.0646665),
    ),
    RouteDestination(
      name: 'Westmead International School',
      address: 'Batangas City',
      location: LatLng(13.7853954, 121.0758034),
    ),
  ];
}
