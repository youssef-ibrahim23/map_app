import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:map_app/features/map/model/search_result.dart';
import 'package:map_app/features/map/model/transport_mode.dart';
import 'package:url_launcher/url_launcher.dart';

class MapServices {
  Future<bool> checkAndRequestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestLocationPermission();

      if (!hasPermission) {
        return null;
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
    } catch (e) {
      return null;
    }
  }

  Future<String> getAddressFromLatLng(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isEmpty) {
        return 'Address not available';
      }

      final place = placemarks.first;

      final parts = <String>[
        if (place.street?.trim().isNotEmpty == true) place.street!.trim(),
        if (place.subThoroughfare?.trim().isNotEmpty == true)
          place.subThoroughfare!.trim(),
        if (place.locality?.trim().isNotEmpty == true) place.locality!.trim(),
        if (place.administrativeArea?.trim().isNotEmpty == true)
          place.administrativeArea!.trim(),
        if (place.country?.trim().isNotEmpty == true)
          place.country!.trim(),
      ];

      if (parts.isEmpty) {
        return 'Address not available';
      }

      return parts.join(', ');
    } catch (e) {
      return 'Address not available';
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

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return [];
      }

      final routes = data['routes'];

      if (routes is! List || routes.isEmpty) {
        return [];
      }

      final geometry = routes[0]['geometry'];

      if (geometry is! Map<String, dynamic>) {
        return [];
      }

      final coordinates = geometry['coordinates'];

      if (coordinates is! List) {
        return [];
      }

      return coordinates
          .whereType<List>()
          .where((coordinate) => coordinate.length >= 2)
          .map(
            (coordinate) => LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        ),
      )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> openGoogleMapsNavigation(
      double lat,
      double lng,
      TransportMode transportMode,
      ) async {
    final mode = transportMode == TransportMode.driving ? 'd' : 'w';

    final googleMapsUri = Uri.parse(
      'google.navigation:q=$lat,$lng&mode=$mode',
    );

    try {
      final launched = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return;
      }

      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );

      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      try {
        final webUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        );

        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }
  }

  Future<List<SearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeQueryComponent(
        query.trim(),
      );

      final url =
          'https://nominatim.openstreetmap.org/search'
          '?q=$encodedQuery'
          '&format=json'
          '&limit=5';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MapApp/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(SearchResult.fromJson)
          .toList();
    } catch (e) {
      return [];
    }
  }
}