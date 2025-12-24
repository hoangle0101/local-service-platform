import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';

class MiniMapWidget extends StatelessWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final bool interactive;

  final MapController? mapController;

  const MiniMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.markers = const [],
    this.interactive = true,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'vn.hoangle.localservice.provider',
        ),
        MarkerLayer(
          markers: [
            // Current Location Marker (standard for driver apps)
            Marker(
              point: initialCenter,
              width: 60,
              height: 60,
              child: _buildLocationMarker(),
            ),
            ...markers,
          ],
        ),
      ],
    );
  }

  Widget _buildLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
