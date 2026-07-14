import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_app/features/map/model/transport_mode.dart';
import 'package:map_app/features/map/model/search_result.dart';
import 'package:map_app/features/map/services/map_services.dart';
import '../../../core/constants/app_colors.dart';
import '../model/map_model.dart';
import '../view/widgets/bottom_sheet_widget.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

final mapProvider = StateNotifierProvider<MapViewModel, MapModel>((ref) {
  return MapViewModel()..getCurrentLocation();
},
  isAutoDispose: true,
);

class MapViewModel extends StateNotifier<MapModel> {
  MapViewModel() : super(MapModel()) {
    _startLocationStream();
  }

  final MapController mapController = MapController();
  StreamSubscription<Position>? _locationSubscription;

  void _startLocationStream() async {
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) {
          final latLng = LatLng(position.latitude, position.longitude);

          state = state.copyWith(currentLocation: latLng);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapController.move(latLng, state.zoom);
          });
        });
  }

  Future<void> getCurrentLocation() async {
    final latLng = await MapServices().getCurrentLocation();

    state = state.copyWith(currentLocation: latLng);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapController.move(state.currentLocation!, state.zoom);
    });
  }

  Future<void> goToCurrentLocation() async {
    if (state.currentLocation != null) {
      mapController.move(state.currentLocation!, state.zoom);
    }
  }

  Future<void> zoomIn() async {
    final newZoom = state.zoom + 1;
    state = state.copyWith(zoom: newZoom);
    mapController.move(mapController.camera.center, newZoom);
  }

  Future<void> zoomOut() async {
    final newZoom = state.zoom - 1;
    state = state.copyWith(zoom: newZoom);
    mapController.move(mapController.camera.center, newZoom);
  }

  Future<void> markLocation(LatLng point, BuildContext? context) async {
    final marker = Marker(
      point: point,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.location_pin,
        color: AppColors.primaryColor,
        size: 40,
      ),
    );

    state = state.copyWith(marker: marker);

    mapController.move(point, state.zoom);

    String address = await MapServices().getAddressFromLatLng(point);

    state = state.copyWith(selectedAddress: address);
  }

  void clearMarker() {
    state = state.copyWith(
      clearMarker: true,
      clearAddress: true,
      clearRoutePoints: true,
      transportMode: TransportMode.driving,
    );
  }

  Future<void> openGoogleMapsNavigation(double lat, double lng) async {
    await MapServices().openGoogleMapsNavigation(lat, lng , state.transportMode);
  }

  Future<void> drawRouteTo(LatLng destination) async {
    final route = await MapServices().getRoute(
      state.currentLocation!,
      destination,
      state.transportMode,
    );
    state = state.copyWith(routePoints: route);

    mapController.fitCamera(
      CameraFit.bounds(bounds: LatLngBounds.fromPoints(route)),
    );
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: [],
        isSearching: false,
        clearSearchResults: true,
      );
      return;
    }

    state = state.copyWith(
      searchQuery: query,
      isSearching: true,
    );

    final results = await MapServices().searchLocation(query);

    state = state.copyWith(
      searchResults: results,
      isSearching: false,
    );
  }

  void selectSearchResult(SearchResult result) {
    final latLng = LatLng(result.lat, result.lon);
    
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      clearSearchResults: true,
    );

    mapController.move(latLng, state.zoom);
    
    markLocation(latLng, null);
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      clearSearchResults: true,
    );
  }

  void showMarkerBottomSheet(BuildContext context) {
    if (state.marker != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return BottomSheetWidget(point: state.marker!.point);
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

}