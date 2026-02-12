import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gebeta_gl/gebeta_gl.dart';

import '../constants/app_constants.dart';

typedef OnMapCreatedCallback = void Function(GebetaMapController controller);
typedef OnMapTapCallback = void Function(LatLng latLng);

class MapMarker {
  final LatLng position;
  final String? iconImage;
  final double iconSize;
  final String? iconAnchor;

  const MapMarker({
    required this.position,
    this.iconImage,
    this.iconSize = 1.5,
    this.iconAnchor = 'bottom',
  });
}

class MapPolyline {
  final List<LatLng> points;
  final String color;
  final double width;

  const MapPolyline({
    required this.points,
    this.color = '#2196F3',
    this.width = 4.0,
  });
}

class GebetaMapWidget extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final List<MapMarker> markers;
  final List<MapPolyline> polylines;
  final bool showUserLocation;
  final OnMapCreatedCallback? onMapCreated;
  final OnMapTapCallback? onTap;
  final bool interactive;
  final EdgeInsets? padding;

  const GebetaMapWidget({
    super.key,
    this.initialCenter,
    this.initialZoom = AppConstants.defaultZoom,
    this.markers = const [],
    this.polylines = const [],
    this.showUserLocation = false,
    this.onMapCreated,
    this.onTap,
    this.interactive = true,
    this.padding,
  });

  @override
  State<GebetaMapWidget> createState() => GebetaMapWidgetState();
}

class GebetaMapWidgetState extends State<GebetaMapWidget> {
  GebetaMapController? _controller;
  bool _markerImageLoaded = false;
  final List<Symbol> _symbols = [];
  final List<Line> _lines = [];

  @override
  void didUpdateWidget(GebetaMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _markerImageLoaded) {
      _updateMapElements();
    }
  }

  Future<void> _onMapCreated(GebetaMapController controller) async {
    _controller = controller;
    await _loadMarkerImage(controller);
    _markerImageLoaded = true;
    await _updateMapElements();
    widget.onMapCreated?.call(controller);
  }

  Future<void> _loadMarkerImage(GebetaMapController controller) async {
    try {
      final byteData = await rootBundle.load('assets/icons/marker.png');
      await controller.addImage(
        'default-marker',
        byteData.buffer.asUint8List(),
      );
    } catch (_) {
      // Marker asset not found — symbols will use default
    }
  }

  Future<void> _updateMapElements() async {
    final controller = _controller;
    if (controller == null) return;

    for (final symbol in _symbols) {
      await controller.removeSymbol(symbol);
    }
    _symbols.clear();

    for (final line in _lines) {
      await controller.removeLine(line);
    }
    _lines.clear();

    for (final marker in widget.markers) {
      final symbol = await controller.addSymbol(
        SymbolOptions(
          geometry: marker.position,
          iconImage: marker.iconImage ?? 'default-marker',
          iconSize: marker.iconSize,
          iconAnchor: marker.iconAnchor,
        ),
      );
      _symbols.add(symbol);
    }

    for (final polyline in widget.polylines) {
      final line = await controller.addLine(
        LineOptions(
          geometry: polyline.points,
          lineColor: polyline.color,
          lineWidth: polyline.width,
        ),
      );
      _lines.add(line);
    }
  }

  void animateCamera(LatLng target, {double? zoom}) {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(target, zoom ?? widget.initialZoom),
    );
  }

  void fitBounds(LatLng sw, LatLng ne, {double padding = 50}) {
    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne),
        left: padding,
        right: padding,
        top: padding,
        bottom: padding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter ??
        const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return GebetaMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: widget.initialZoom,
      ),
      apiKey: AppConstants.gebetaMapsApiKey,
      onMapCreated: _onMapCreated,
      onMapClick: widget.onTap != null
          ? (point, latLng) => widget.onTap!(latLng)
          : null,
      myLocationEnabled: widget.showUserLocation,
      myLocationTrackingMode: widget.showUserLocation
          ? MyLocationTrackingMode.tracking
          : MyLocationTrackingMode.none,
      compassViewPosition: CompassViewPosition.topRight,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
    );
  }
}
