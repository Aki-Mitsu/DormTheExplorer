import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum DormLocationIssue {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class DormLocationException implements Exception {
  const DormLocationException(this.issue, this.message);

  final DormLocationIssue issue;
  final String message;

  @override
  String toString() => message;
}

class DormLocationService {
  DormLocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  DateTime? _lastReverseGeocodeRequest;

  Future<LatLng> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DormLocationException(
        DormLocationIssue.servicesDisabled,
        'Location services are turned off.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DormLocationException(
        DormLocationIssue.permissionDeniedForever,
        'Location permission is permanently denied.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const DormLocationException(
        DormLocationIssue.permissionDenied,
        'Location permission was denied.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<String?> reverseGeocode(LatLng location) async {
    final lastRequest = _lastReverseGeocodeRequest;
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
      }
    }
    _lastReverseGeocodeRequest = DateTime.now();

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'addressdetails': '1',
      },
    );
    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent':
                'DormTheExplorer/1.0 (https://github.com/shirokase/Dorm-the-Explorer)',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StateError(
        response.statusCode == 429
            ? 'The address lookup is busy. Please try again shortly.'
            : 'Could not look up the address (HTTP ${response.statusCode}).',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid address lookup response.');
    }
    final address = payload['display_name'];
    return address is String && address.trim().isNotEmpty
        ? address.trim()
        : null;
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  void close() => _client.close();
}
