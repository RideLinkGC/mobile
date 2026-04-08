import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../../../emergency/widgets/emergency_alert_sheet.dart';
import '../../trip/providers/trip_provider.dart';
import '../widgets/driver_current_trip_card.dart';

class DriverActiveScreen extends StatefulWidget {
  const DriverActiveScreen({super.key});

  @override
  State<DriverActiveScreen> createState() => _DriverActiveScreenState();
}

class _DriverActiveScreenState extends State<DriverActiveScreen> {
  static const double _kMapHeightFraction = 0.7;

  final GlobalKey<GebetaMapWidgetState> _mapKey =
      GlobalKey<GebetaMapWidgetState>();

  LatLng? _userLocation;
  TripModel? _activeTrip;
  RouteResult? _directionRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<LocationService>().ensureLocationPermissionRequested();
      await _loadActiveTrip();
      await _getUserLocation();
    });
  }

  TripModel? _pickActiveTrip(List<TripModel> trips) {
    final inProgress = trips
        .where((t) => t.status == TripStatus.inProgress)
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    if (inProgress.isNotEmpty) return inProgress.first;
    return null;
  }

  Future<void> _loadActiveTrip() async {
    final tripProvider = context.read<TripProvider>();
    await tripProvider.loadDriverTrips();

    if (!mounted) return;
    final active = _pickActiveTrip(tripProvider.driverTrips);
    setState(() {
      _activeTrip = active;
      _directionRoute = null;
    });

    if (active == null) return;

    await tripProvider.loadTripBookings(active.id);
    await _loadDirectionRoute(active);
  }

  Future<void> _loadDirectionRoute(TripModel trip) async {
    if (trip.routeCoordinates.length < 2) return;
    final maps = context.read<GebetaMapsService>();
    final first = trip.routeCoordinates.first;
    final last = trip.routeCoordinates.last;
    try {
      final route = await maps.getRoute(
        originLat: first.lat,
        originLng: first.lng,
        destLat: last.lat,
        destLng: last.lng,
      );
      if (!mounted) return;
      setState(() => _directionRoute = route);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
    } catch (_) {}
  }

  Future<void> _getUserLocation() async {
    final locationService = context.read<LocationService>();
    final pos = await locationService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadActiveTrip(),
      _getUserLocation(),
    ]);
  }

  void _fitMapToRoute() {
    final state = _mapKey.currentState;
    if (state == null) return;

    final points = <LatLng>[];
    final trip = _activeTrip;
    final rr = _directionRoute;

    if (rr != null && rr.polylinePoints.length >= 2) {
      for (final p in rr.polylinePoints) {
        if (p.length >= 2) points.add(LatLng(p[0], p[1]));
      }
    } else if (trip != null && trip.routeCoordinates.length >= 2) {
      points.addAll(trip.routeCoordinates.map((c) => LatLng(c.lat, c.lng)));
    } else {
      points.add(const LatLng(AppConstants.defaultLat, AppConstants.defaultLng));
    }
    if (_userLocation != null) points.add(_userLocation!);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tripProvider = context.watch<TripProvider>();

    final trip = _activeTrip;
    final rr = _directionRoute;
    final etaMinutes = rr != null && rr.durationMinutes > 0
        ? rr.durationMinutes.round().clamp(1, 24 * 60)
        : null;
    final distanceKm = rr != null && rr.distanceKm > 0 ? rr.distanceKm : null;

    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = screenH * _kMapHeightFraction;

    return Scaffold(
      appBar: AppBar(
        leading: const ShellMenuButton(),
        title: Text(l10n.activeTrip),
        centerTitle: true,
      ),
      backgroundColor: theme.brightness == Brightness.dark
          ? AppColors.darkBackground
          : scheme.surface,
      floatingActionButton: trip == null
          ? null
          : FloatingActionButton(
              heroTag: 'driver_active_sos',
              tooltip: l10n.sos,
              onPressed: () => showEmergencyAlertFlow(context, trip.id),
              backgroundColor: AppColors.sosRed,
              foregroundColor: Colors.white,
              child: const Icon(Icons.emergency_rounded),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: AppColors.primary,
        edgeOffset: mapHeight * 0.5,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: mapHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GebetaMapWidget(
                      key: _mapKey,
                      initialCenter: _userLocation ??
                          const LatLng(
                            AppConstants.defaultLat,
                            AppConstants.defaultLng,
                          ),
                      initialZoom: 13.4,
                      showUserLocation: true,
                      interactive: true,
                      markers: _buildMarkers(trip, _userLocation),
                      polylines: _buildPolylines(trip, _directionRoute),
                      onTap: (_) {
                        final id = trip?.id;
                        if (id != null && id.isNotEmpty) {
                          context.push('/tracking/$id');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: tripProvider.loading && trip == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : trip == null
                        ? _NoActiveTrip(
                            onGoHome: () => context.go('/driver'),
                          )
                        : DriverCurrentTripCard(
                            trip: trip,
                            bookings: tripProvider.tripBookings,
                            etaMinutes: etaMinutes,
                            distanceKm: distanceKm,
                            onOpen: () => context.push('/trip-detail/${trip.id}'),
                            onOpenTracking: () =>
                                context.push('/tracking/${trip.id}'),
                            onRequests: () =>
                                context.push('/booking-requests/${trip.id}'),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, size: 64, color: AppColors.textHintLight),
          const SizedBox(height: 14),
          Text(
            'No active trip',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a scheduled trip to see it here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onGoHome,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(l10n.home),
          ),
        ],
      ),
    );
  }
}

List<MapMarker> _buildMarkers(TripModel? trip, LatLng? userLocation) {
  final markers = <MapMarker>[];
  if (trip != null && trip.routeCoordinates.isNotEmpty) {
    markers.add(
      MapMarker(
        position: LatLng(
          trip.routeCoordinates.first.lat,
          trip.routeCoordinates.first.lng,
        ),
      ),
    );
    if (trip.routeCoordinates.length >= 2) {
      markers.add(
        MapMarker(
          position: LatLng(
            trip.routeCoordinates.last.lat,
            trip.routeCoordinates.last.lng,
          ),
          iconSize: 1.8,
        ),
      );
    }
  }
  if (userLocation != null) {
    markers.add(MapMarker(position: userLocation, iconSize: 1.4));
  }
  return markers;
}

List<MapPolyline> _buildPolylines(TripModel? trip, RouteResult? route) {
  if (route != null && route.polylinePoints.length >= 2) {
    final points = route.polylinePoints
        .where((p) => p.length >= 2)
        .map((p) => LatLng(p[0], p[1]))
        .toList();
    return [
      MapPolyline(points: points, color: AppColors.primaryMapHex, width: 5),
    ];
  }
  if (trip != null && trip.routeCoordinates.length >= 2) {
    final points =
        trip.routeCoordinates.map((c) => LatLng(c.lat, c.lng)).toList();
    return [
      MapPolyline(points: points, color: AppColors.primaryMapHex, width: 5),
    ];
  }
  return [];
}

