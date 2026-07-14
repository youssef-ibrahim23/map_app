import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_app/core/constants/app_colors.dart';
import 'package:map_app/features/map/model/map_model.dart';
import 'package:map_app/features/map/model/search_result.dart';
import '../view_model/map_view_model.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(mapProvider.notifier).searchLocation(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);
    final vm = ref.read(mapProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Map App",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.map_rounded, color: Colors.white, size: 26),
          ],
        ),
        centerTitle: true,
        elevation: 6,
        shadowColor: AppColors.primaryColor.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: state.currentLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading map...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SizedBox.expand(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: vm.mapController,
                    options: MapOptions(
                      initialCenter: state.currentLocation!,
                      initialZoom: state.zoom,
                      onTap: (tapPosition, point) {
                        vm.clearMarker();
                        vm.markLocation(point, context);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                        errorImage: AssetImage('assets/logo.png'),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: state.currentLocation!,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primaryColor,
                              size: 36,
                            ),
                          ),
                          if (state.marker != null) state.marker!,
                        ],
                      ),
                      if (state.routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: state.routePoints,
                              strokeWidth: 5,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search location...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.primaryColor),
                            onPressed: () {
                              _searchController.clear();
                              vm.clearSearch();
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.searchResults.isNotEmpty)
                    Positioned(
                      top: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: state.isSearching
                            ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: AppColors.primaryColor),
                          ),
                        )
                            : ListView.separated(
                          shrinkWrap: true,
                          itemCount: state.searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = state.searchResults[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: AppColors.primaryColor,
                              ),
                              title: Text(
                                result.name,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                vm.selectSearchResult(result);
                                _searchController.clear();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  if (state.marker != null)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => vm.showMarkerBottomSheet(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline_rounded,
                                        color: AppColors.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'View Location Details',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          if (state.selectedAddress != null)
                                            Text(
                                              state.selectedAddress!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'My Location',
                onPressed: () {
                  vm.goToCurrentLocation();
                },
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
                elevation: 4,
                child: const Icon(Icons.my_location_rounded, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'Clear Marks',
                onPressed: () {
                  vm.clearMarker();
                },
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
                elevation: 4,
                child: const Icon(Icons.location_off_sharp, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'zoomIn',
                onPressed: () {
                  vm.zoomIn();
                },
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
                elevation: 4,
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'zoomOut',
                onPressed: () {
                  vm.zoomOut();
                },
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
                elevation: 4,
                child: const Icon(Icons.remove_rounded, size: 28),
              ),
            ),
            if(state.marker != null) SizedBox(height: 65,),
          ],
        ),
      ),
    );
  }

}
