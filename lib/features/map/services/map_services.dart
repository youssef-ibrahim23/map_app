import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/features/map/model/transport_mode.dart';
import 'package:map_app/features/map/model/search_result.dart';
import 'package:url_launcher/url_launcher.dart';

class MapServices {
  static const LatLng cairoLocation = LatLng(
    30.0444,
    31.2357,
  );

  Future<void> checkAndRequestLocationPermission() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  Future<LatLng> getCurrentLocation() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return cairoLocation;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return cairoLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      return cairoLocation;
    }
  }

  Future<String> getAddressFromLatLng(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isEmpty) {
        return "Address not available";
      }

      final place = placemarks.first;

      return "${place.street ?? ''} ${place.subThoroughfare ?? ''}, "
          "${place.locality ?? ''}, "
          "${place.administrativeArea ?? ''}, "
          "${place.country ?? ''}";
    } catch (_) {
      return "Address not available";
    }
  }

  Future<List<LatLng>> getRoute(
      LatLng start,
      LatLng end,
      TransportMode transportMode,
      ) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/'
          '${transportMode.osrmProfile}/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final coords =
      data['routes'][0]['geometry']['coordinates'] as List;

      return coords
          .map(
            (c) => LatLng(
          c[1].toDouble(),
          c[0].toDouble(),
        ),
      )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> openGoogleMapsNavigation(
      double lat,
      double lng,
      TransportMode transportMode,
      ) async {
    final mode =
    transportMode == TransportMode.driving ? 'd' : 'w';

    final uri = Uri.parse(
      "google.navigation:q=$lat,$lng&mode=$mode",
    );

    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<List<SearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());

      final url =
          'https://nominatim.openstreetmap.org/search'
          '?q=$encodedQuery'
          '&format=json'
          '&limit=5';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MapApp',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map(
            (json) => SearchResult.fromJson(json),
      )
          .toList();
    } catch (_) {
      return [];
    }
  }
}