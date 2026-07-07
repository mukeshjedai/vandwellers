import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/campsite.dart';

class CampsitesMap extends StatelessWidget {
  const CampsitesMap({
    super.key,
    required this.campsites,
    this.onCampsiteTap,
    this.selectedCampsiteId,
  });

  final List<Campsite> campsites;
  final ValueChanged<Campsite>? onCampsiteTap;
  final String? selectedCampsiteId;

  LatLng get _center {
    if (campsites.isEmpty) return const LatLng(-25.2744, 133.7751);
    final avgLat =
        campsites.map((c) => c.latitude).reduce((a, b) => a + b) / campsites.length;
    final avgLng =
        campsites.map((c) => c.longitude).reduce((a, b) => a + b) / campsites.length;
    return LatLng(avgLat, avgLng);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _center,
            initialZoom: campsites.length == 1 ? 8 : 4.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vandwellers.app',
            ),
            MarkerLayer(
              markers: campsites
                  .where((c) => c.latitude != 0 || c.longitude != 0)
                  .map((campsite) {
                final selected = campsite.id == selectedCampsiteId;
                return Marker(
                  point: LatLng(campsite.latitude, campsite.longitude),
                  width: selected ? 44 : 36,
                  height: selected ? 44 : 36,
                  child: GestureDetector(
                    onTap: () => onCampsiteTap?.call(campsite),
                    child: Icon(
                      Icons.location_on,
                      size: selected ? 44 : 36,
                      color: selected ? primary : primary.withValues(alpha: 0.85),
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
