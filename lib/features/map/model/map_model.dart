import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_app/features/map/model/transport_mode.dart';
import 'package:map_app/features/map/model/search_result.dart';

class MapModel {
  final LatLng? currentLocation;
  final double zoom;
  final Marker? marker;
  final String? selectedAddress;
  final List<LatLng> routePoints;
  TransportMode transportMode;
  final String searchQuery;
  final List<SearchResult> searchResults;
  final bool isSearching;

  MapModel({
    this.currentLocation,
    this.zoom = 18,
    this.marker,
    this.selectedAddress,
    this.routePoints = const [],
    this.transportMode = TransportMode.driving,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
  });

  MapModel copyWith({
    LatLng? currentLocation,
    double? zoom,
    Marker? marker,
    String? selectedAddress,
    List<LatLng>? routePoints,
    TransportMode? transportMode,
    String? searchQuery,
    List<SearchResult>? searchResults,
    bool? isSearching,
    bool clearMarker = false,
    bool clearAddress = false,
    bool clearRoutePoints = false,
    bool clearSearchResults = false,
  }) {
    return MapModel(
      currentLocation: currentLocation ?? this.currentLocation,
      zoom: zoom ?? this.zoom,
      marker: clearMarker ? null : (marker ?? this.marker),
      selectedAddress: clearAddress ? null : (selectedAddress ?? this.selectedAddress),
      routePoints: clearRoutePoints ? [] : (routePoints ?? this.routePoints),
      transportMode: transportMode ?? this.transportMode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: clearSearchResults ? [] : (searchResults ?? this.searchResults),
      isSearching: isSearching ?? this.isSearching,
    );
  }
}
