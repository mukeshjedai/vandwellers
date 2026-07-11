import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/campsite.dart';
import 'campsite_tags.dart';

class CampsiteMap extends StatefulWidget {
  const CampsiteMap({
    super.key,
    required this.campsites,
    this.mapController,
    this.pickMode = false,
    this.pendingLocation,
    this.currentLocation,
    this.selectedCampsiteId,
    this.onTap,
    this.onCampsiteTap,
    this.fullScreen = false,
    this.zoomOnTap = true,
  });

  final List<Campsite> campsites;
  final MapController? mapController;
  final bool pickMode;
  final LatLng? pendingLocation;
  final LatLng? currentLocation;
  final String? selectedCampsiteId;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<Campsite>? onCampsiteTap;
  final bool fullScreen;
  final bool zoomOnTap;

  static const australiaCenter = LatLng(-25.27, 133.77);
  static const defaultZoom = 4.5;

  @override
  State<CampsiteMap> createState() => _CampsiteMapState();
}

class _CampsiteMapState extends State<CampsiteMap> {
  late final MapController _mapController =
      widget.mapController ?? MapController();
  var _didInitialFit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent(force: true));
  }

  @override
  void didUpdateWidget(CampsiteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campsites != widget.campsites && !_didInitialFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent(force: true));
    }
  }

  void zoomTo(LatLng point, {double zoom = 14}) {
    _mapController.move(point, zoom);
  }

  void _fitToContent({bool force = false}) {
    if (!mounted) return;
    if (_didInitialFit && !force) return;

    final points = <LatLng>[
      for (final site in widget.campsites)
        if (site.latitude != 0 || site.longitude != 0)
          LatLng(site.latitude, site.longitude),
      if (widget.pendingLocation != null) widget.pendingLocation!,
      if (widget.currentLocation != null) widget.currentLocation!,
    ];

    if (points.isEmpty) {
      final center = widget.currentLocation ?? CampsiteMap.australiaCenter;
      _mapController.move(center, widget.currentLocation != null ? 10 : CampsiteMap.defaultZoom);
      _didInitialFit = true;
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 11);
      _didInitialFit = true;
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.only(
          top: widget.fullScreen ? 96 : 48,
          bottom: widget.fullScreen ? 220 : 48,
          left: 48,
          right: 48,
        ),
        maxZoom: 12,
      ),
    );
    _didInitialFit = true;
  }

  void _handleMapTap(LatLng point) {
    if (widget.pickMode) {
      widget.onTap?.call(point);
      return;
    }

    if (widget.zoomOnTap) {
      final nextZoom = (_mapController.camera.zoom + 2).clamp(3.0, 18.0);
      _mapController.move(point, nextZoom);
    }
    widget.onTap?.call(point);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final markers = <Marker>[
      for (final site in widget.campsites)
        if (site.latitude != 0 || site.longitude != 0)
          Marker(
            point: LatLng(site.latitude, site.longitude),
            width: 140,
            height: 92,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => widget.onCampsiteTap?.call(site),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: widget.selectedCampsiteId == site.id
                        ? primary.withValues(alpha: 0.95)
                        : Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            site.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CampsiteTagWrap(campsite: site, compact: true),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    color: widget.selectedCampsiteId == site.id
                        ? Colors.lightGreenAccent
                        : primary,
                    size: 34,
                  ),
                ],
              ),
            ),
          ),
      if (widget.currentLocation != null)
        Marker(
          point: widget.currentLocation!,
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      if (widget.pendingLocation != null)
        Marker(
          point: widget.pendingLocation!,
          width: 44,
          height: 44,
          child: const Icon(
            Icons.add_location_alt,
            color: Colors.lightGreenAccent,
            size: 40,
          ),
        ),
    ];

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.currentLocation ?? CampsiteMap.australiaCenter,
        initialZoom: widget.currentLocation != null
            ? 10
            : CampsiteMap.defaultZoom,
        minZoom: 2,
        maxZoom: 18,
        onTap: (_, point) => _handleMapTap(point),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.vandwellers.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          maxNativeZoom: 19,
          panBuffer: 1,
        ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {},
            ),
          ],
        ),
      ],
    );

    if (widget.fullScreen) {
      return Stack(
        children: [
          Positioned.fill(child: map),
          if (widget.pickMode)
            Positioned(
              top: 88,
              left: 16,
              right: 16,
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
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        color: const Color(0xFF1C2330),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox.expand(child: map),
            if (widget.pickMode)
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
          ],
        ),
      ),
    );
  }
}
