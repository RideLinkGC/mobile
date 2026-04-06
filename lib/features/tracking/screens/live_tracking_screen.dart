import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/gebeta_maps_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gebeta_map_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../driver/trip/providers/trip_provider.dart';
import '../../emergency/widgets/emergency_alert_sheet.dart';
import '../providers/tracking_provider.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String tripId;

  const LiveTrackingScreen({super.key, required this.tripId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey();

  RouteResult? _route;
  TripModel? _trip;
  bool _endingTrip = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTripData();
      if (!mounted) return;
      await _startTracking();
    });
  }

  Future<void> _loadTripData() async {
    final trip =
        await context.read<TripProvider>().getTripById(widget.tripId);
    if (mounted) {
      setState(() => _trip = trip);
      // Fetch directions/ETA/distance from Gebeta when we have endpoints.
      // (The previous `routeCoordinates.isEmpty` check was inverted and never loaded.)
      if (trip != null && trip.routeCoordinates.length >= 2) {
        await _loadRoute();
      }
    }
  }

  Future<void> _startTracking() async {
    final authProvider = context.read<AuthProvider>();
    final trackingProvider = context.read<TrackingProvider>();
    final storage = context.read<StorageService>();

    // Convex `location:*` handlers use `requireAuth`; JWT must be on the client first.
    await authProvider.syncConvexAuth();
    if (!mounted) return;

    final convexJwt = await storage.getConvexJwt();
    if (convexJwt == null || convexJwt.isEmpty) {
      // Demo login or missing `/auth/token` — skip Convex to avoid requireAuth errors.
      return;
    }

    if (authProvider.isDriver) {
      final driverId = await storage.getDriverId() ?? '';
      await trackingProvider.startBroadcasting(
        widget.tripId,
        driverId: driverId,
      );
    } else {
      await trackingProvider.startListening(widget.tripId);
    }
  }

  Future<void> _loadRoute() async {
    final trip = _trip;
    if (trip == null) return;

    final mapsService = context.read<GebetaMapsService>();
    final originCoords = trip.routeCoordinates.isNotEmpty
        ? trip.routeCoordinates.first
        : null;
    final destCoords = trip.routeCoordinates.isNotEmpty
        ? trip.routeCoordinates.last
        : null;

    if (originCoords == null || destCoords == null) return;

    final route = await mapsService.getRoute(
      originLat: originCoords.lat,
      originLng: originCoords.lng,
      destLat: destCoords.lat,
      destLng: destCoords.lng,
    );
    if (mounted) {
      setState(() => _route = route);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
    }
  }

  void _fitMapToRoute() {
    final state = _mapKey.currentState;
    if (state == null) return;

    final points = <LatLng>[];
    final rr = _route;
    if (rr != null && rr.polylinePoints.length >= 2) {
      for (final p in rr.polylinePoints) {
        if (p.length >= 2) points.add(LatLng(p[0], p[1]));
      }
    } else {
      points.addAll([_originLatLng, _destLatLng]);
    }

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    const pad = 0.004;
    state.fitBounds(
      LatLng(minLat - pad, minLng - pad),
      LatLng(maxLat + pad, maxLng + pad),
      padding: 48,
    );
  }

  LatLng get _originLatLng {
    if (_trip != null && _trip!.routeCoordinates.isNotEmpty) {
      final c = _trip!.routeCoordinates.first;
      return LatLng(c.lat, c.lng);
    }
    return const LatLng(9.0192, 38.7525);
  }

  LatLng get _destLatLng {
    if (_trip != null && _trip!.routeCoordinates.isNotEmpty) {
      final c = _trip!.routeCoordinates.last;
      return LatLng(c.lat, c.lng);
    }
    return const LatLng(9.0300, 38.7800);
  }

  List<MapMarker> _buildMarkers(LatLng? driverPos) {
    final markers = <MapMarker>[
      MapMarker(position: _originLatLng),
      MapMarker(position: _destLatLng),
    ];
    if (driverPos != null) {
      markers.add(MapMarker(position: driverPos, iconSize: 2.0));
    }
    return markers;
  }

  List<MapPolyline> get _polylines {
    if (_route != null && _route!.polylinePoints.length >= 2) {
      final points = _route!.polylinePoints
          .where((p) => p.length >= 2)
          .map((p) => LatLng(p[0], p[1]))
          .toList();
      return [
        MapPolyline(
          points: points,
          color: AppColors.primaryMapHex,
          width: 5,
        ),
      ];
    }
    if (_trip != null && _trip!.routeCoordinates.length >= 2) {
      return [
        MapPolyline(
          points: _trip!.routeCoordinates
              .map((c) => LatLng(c.lat, c.lng))
              .toList(),
          color: AppColors.primaryMapHex,
          width: 5,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final trackingProvider = context.watch<TrackingProvider>();
    final isDriver = authProvider.isDriver;
    final driverPos = trackingProvider.driverPosition;

    final driverName = _trip?.driverName ?? 'Driver';
    final vehicleInfo = _trip?.vehicleModel ?? '';
    final rating = _trip?.driverRating?.toStringAsFixed(1) ?? '-';

    return Scaffold(
      body: Stack(
        children: [
          GebetaMapWidget(
            key: _mapKey,
            initialCenter: driverPos ?? _originLatLng,
            initialZoom: 14,
            markers: _buildMarkers(driverPos),
            polylines: _polylines,
            showUserLocation: true,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  trackingProvider.stopTracking();
                  context.pop();
                },
              ),
            ),
          ),
          if (trackingProvider.error != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 60,
              right: 60,
              child: Material(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.sosRed.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Text(
                    trackingProvider.error!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.person,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '$vehicleInfo • $rating ★',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.eta,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondaryLight),
                              ),
                              Text(
                                _route != null && _route!.durationMinutes > 0
                                    ? '${_route!.durationMinutes.round().clamp(1, 24 * 60)} min'
                                    : '-- min',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Distance',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondaryLight),
                              ),
                              Text(
                                _route != null && _route!.distanceKm > 0
                                    ? '${_route!.distanceKm.toStringAsFixed(1)} km'
                                    : _trip != null && _trip!.distanceKm > 0
                                        ? '${_trip!.distanceKm.toStringAsFixed(1)} km'
                                        : '-- km',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isDriver)
                        AppButton(
                          text: 'End Trip',
                          isLoading: _endingTrip,
                          onPressed: () async {
                            if (_endingTrip) return;
                            setState(() => _endingTrip = true);
                            final tripProvider = context.read<TripProvider>();
                            final completed =
                                await tripProvider.completeTrip(widget.tripId);
                            if (!context.mounted) return;
                            if (completed) {
                              await trackingProvider.endTrip();
                              if (context.mounted) context.pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tripProvider.error ??
                                        'Failed to end trip. Please try again.',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                            if (mounted) setState(() => _endingTrip = false);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 280,
            child: FloatingActionButton(
              onPressed: () =>
                  showEmergencyAlertFlow(context, widget.tripId),
              backgroundColor: AppColors.sosRed,
              child: const Icon(Icons.emergency, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
