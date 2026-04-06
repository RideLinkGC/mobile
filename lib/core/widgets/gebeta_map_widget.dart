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
    this.color = '#0CCFED',
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
  /// Style loaded; [lineManager] is available.
  bool _styleReady = false;
  /// `default-marker` image registered with the style (required for [addSymbol]).
  bool _markerImageReady = false;
  final List<Symbol> _symbols = [];
  final List<Line> _lines = [];

  @override
  void didUpdateWidget(GebetaMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _styleReady) {
      _updateMapElements();
    }
  }

  void _onMapCreated(GebetaMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }

  /// Per Gebeta/MapLibre: do not call [addSymbol]/[addLine] until the style is loaded.
  void _onStyleLoaded() {
    _applyAnnotationsAfterStyle();
  }

  Future<void> _applyAnnotationsAfterStyle() async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final markerOk = await _loadMarkerImage(controller);
    if (!mounted) return;

    setState(() {
      _markerImageReady = markerOk;
      _styleReady = true;
    });

    await _updateMapElements();
  }

  /// Returns whether `default-marker` was added to the map style.
  Future<bool> _loadMarkerImage(GebetaMapController controller) async {
    try {
      final byteData = await rootBundle.load('assets/icons/marker.png');
      await controller.addImage(
        'default-marker',
        byteData.buffer.asUint8List(),
      );
      return true;
    } catch (_) {
      try {
        await controller.addImage(
          'default-marker',
          _embeddedMarkerPng,
        );
        return true;
      } catch (e, st) {
        debugPrint('GebetaMapWidget: could not register marker image: $e\n$st');
        return false;
      }
    }
  }

  /// 1×1 cyan pixel fallback if bundle asset is missing.
  static final Uint8List _embeddedMarkerPng = Uint8List.fromList([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
    0x0a, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0xcf, 0xed, 0xed,
    0x00, 0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d, 0xb4, 0x1c, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
  ]);

  Future<void> _updateMapElements() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;

    try {
      for (final symbol in _symbols) {
        await controller.removeSymbol(symbol);
      }
      _symbols.clear();

      for (final line in _lines) {
        await controller.removeLine(line);
      }
      _lines.clear();

      if (_markerImageReady) {
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
      } else if (widget.markers.isNotEmpty) {
        debugPrint(
          'GebetaMapWidget: skipping ${widget.markers.length} markers (no bitmap)',
        );
      }

      for (final polyline in widget.polylines) {
        if (polyline.points.length < 2) continue;
        final line = await controller.addLine(
          LineOptions(
            geometry: polyline.points,
            lineColor: polyline.color,
            lineWidth: polyline.width,
          ),
        );
        _lines.add(line);
      }
    } catch (e, st) {
      debugPrint('GebetaMapWidget: _updateMapElements failed: $e\n$st');
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
      onStyleLoadedCallback: _onStyleLoaded,
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
