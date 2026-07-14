import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/features/map/model/transport_mode.dart';
import 'package:map_app/features/map/model/search_result.dart';
import 'package:url_launcher/url_launcher.dart';

class MapServices {

  Future<void> checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<String> getAddressFromLatLng(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

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
    print(transportMode.osrmProfile);
    final url =
        'https://router.project-osrm.org/route/v1/${transportMode.osrmProfile}/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';
    print(url);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;

    return coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
  }

  Future<void> openGoogleMapsNavigation(
    double lat,
    double lng,
    TransportMode transportMode,
  ) async {
    String mode = transportMode == TransportMode.driving
        ? 'd'
        : 'w';

    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=$mode");
    print(uri.toString());
    await launchUrl(uri);
  }

  Future<List<SearchResult>> searchLocation(String query) async {
    if (query.isEmpty) return [];
    print(query);

    try {
      final encodedQuery = Uri.encodeComponent(query);
      print(encodedQuery);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'MapApp'},
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      print(data);
      return data.map((json) => SearchResult.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }
}