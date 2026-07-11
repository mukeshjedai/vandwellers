import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/campsite.dart';
import 'campsite_tags.dart';

class CampsiteMap extends StatefulWidget {
  const CampsiteMap({
    super.key,
    required this.campsites,
    this.onMapCreated,
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
  final ValueChanged<GoogleMapController>? onMapCreated;
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
  GoogleMapController? _controller;
  var _didInitialFit = false;
  double _zoom = CampsiteMap.defaultZoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent(force: true));
  }

  @override
  void didUpdateWidget(CampsiteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campsites != widget.campsites ||
        oldWidget.pendingLocation != widget.pendingLocation ||
        oldWidget.currentLocation != widget.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent());
    }
  }

  Future<void> _fitToContent({bool force = false}) async {
    final controller = _controller;
    if (!mounted || controller == null) return;
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
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          center,
          widget.currentLocation != null ? 10 : CampsiteMap.defaultZoom,
        ),
      );
      _didInitialFit = true;
      return;
    }

    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 11));
      _didInitialFit = true;
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        widget.fullScreen ? 120 : 80,
      ),
    );
    _didInitialFit = true;
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (widget.pickMode) {
      widget.onTap?.call(point);
      return;
    }

    if (widget.zoomOnTap && _controller != null) {
      final nextZoom = (_zoom + 2).clamp(3.0, 18.0);
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(point, nextZoom),
      );
    }
    widget.onTap?.call(point);
  }

  String _markerSnippet(Campsite site) {
    final tags = campsiteTags(site);
    return tags.isEmpty ? site.region : tags.join(' · ');
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final site in widget.campsites) {
      if (site.latitude == 0 && site.longitude == 0) continue;
      final selected = widget.selectedCampsiteId == site.id;
      markers.add(
        Marker(
          markerId: MarkerId('campsite_${site.id}'),
          position: LatLng(site.latitude, site.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: site.title,
            snippet: _markerSnippet(site),
          ),
          onTap: () => widget.onCampsiteTap?.call(site),
        ),
      );
    }

    if (widget.pendingLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pending_location'),
          position: widget.pendingLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'New campsite location'),
        ),
      );
    }

    return markers;
  }

  CameraPosition get _initialCamera {
    final center = widget.currentLocation ??
        widget.pendingLocation ??
        CampsiteMap.australiaCenter;
    final zoom = widget.currentLocation != null || widget.pendingLocation != null
        ? 10.0
        : CampsiteMap.defaultZoom;
    return CameraPosition(target: center, zoom: zoom);
  }

  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      initialCameraPosition: _initialCamera,
      markers: _buildMarkers(),
      myLocationEnabled: widget.currentLocation != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
        _fitToContent(force: true);
      },
      onCameraMove: (position) => _zoom = position.zoom,
      onTap: _handleMapTap,
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
                    'Tap the map or search an address below',
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: map,
      ),
    );
  }
}
