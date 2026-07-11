import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/campsite.dart';

class CampsiteMap extends StatelessWidget {
  const CampsiteMap({
    super.key,
    required this.campsites,
    this.pickMode = false,
    this.pendingLocation,
    this.onTap,
    this.onAddPressed,
  });

  final List<Campsite> campsites;
  final bool pickMode;
  final LatLng? pendingLocation;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onAddPressed;

  static const _australiaCenter = LatLng(-25.27, 133.77);
  static const _defaultZoom = 4.0;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      for (final site in campsites)
        if (site.latitude != 0 || site.longitude != 0)
          Marker(
            point: LatLng(site.latitude, site.longitude),
            width: 40,
            height: 40,
              child: Tooltip(
              message: site.title,
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 36,
              ),
            ),
          ),
      if (pendingLocation != null)
        Marker(
          point: pendingLocation!,
          width: 44,
          height: 44,
          child: const Icon(
            Icons.add_location_alt,
            color: Colors.lightGreenAccent,
            size: 40,
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _australiaCenter,
              initialZoom: _defaultZoom,
              onTap: (_, point) => onTap?.call(point),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vandwellers.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (pickMode)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Tap the map to choose a location',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          if (onAddPressed != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'add_campsite_map',
                onPressed: onAddPressed,
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }
}
