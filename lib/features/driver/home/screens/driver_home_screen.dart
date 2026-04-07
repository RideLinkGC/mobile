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
import '../../../auth/providers/auth_provider.dart';
import '../../../emergency/widgets/emergency_alert_sheet.dart';
import '../../trip/providers/trip_provider.dart';
import '../widgets/driver_current_trip_card.dart';
import '../widgets/driver_greeting_banner.dart';
import '../widgets/driver_trip_list_card.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const double _kMapHeightFraction = 0.66;

  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey<GebetaMapWidgetState>();

  LatLng? _userLocation;
  TripModel? _featuredTrip;
  RouteResult? _directionRoute;
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().ensureLocationPermissionRequested();
      context.read<TripProvider>().loadDriverTrips();
      _getUserLocation();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<TripProvider>().loadDriverTrips(),
      _getUserLocation(),
      _refreshFeatured(),
    ]);
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

  TripModel? _pickFeaturedTrip(List<TripModel> trips) {
    final inProgress = trips
        .where((t) => t.status == TripStatus.inProgress)
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    if (inProgress.isNotEmpty) return inProgress.first;

    final upcoming = trips
        .where((t) => t.status == TripStatus.scheduled)
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    if (upcoming.isNotEmpty) return upcoming.first;

    return null;
  }

  Future<void> _refreshFeatured() async {
    final tripProvider = context.read<TripProvider>();
    final maps = context.read<GebetaMapsService>();
    final trips = tripProvider.driverTrips;
    final featured = _pickFeaturedTrip(trips);

    if (!mounted) return;
    if (featured == null) {
      setState(() {
        _featuredTrip = null;
        _directionRoute = null;
      });
      return;
    }

    setState(() => _featuredTrip = featured);

    await tripProvider.loadTripBookings(featured.id);

    if (featured.routeCoordinates.length >= 2) {
      final first = featured.routeCoordinates.first;
      final last = featured.routeCoordinates.last;
      try {
        final route = await maps.getRoute(
          originLat: first.lat,
          originLng: first.lng,
          destLat: last.lat,
          destLng: last.lng,
        );
        if (mounted) {
          setState(() => _directionRoute = route);
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
        }
      } catch (_) {}
    }
  }

  void _fitMapToRoute() {
    final state = _mapKey.currentState;
    if (state == null) return;

    final points = <LatLng>[];
    final trip = _featuredTrip;
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
    final authProvider = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final driverName = authProvider.user?.name ?? 'Driver';
    final trips = tripProvider.driverTrips;

    final featured = _pickFeaturedTrip(trips);
    if (featured != null && _featuredTrip?.id != featured.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFeatured());
    }

    final rr = _directionRoute;
    final etaMinutes = rr != null && rr.durationMinutes > 0
        ? rr.durationMinutes.round().clamp(1, 24 * 60)
        : null;
    final distanceKm = rr != null && rr.distanceKm > 0 ? rr.distanceKm : null;

    final tripBookings = tripProvider.tripBookings;
    final pendingCount =
        tripBookings.where((b) => b.status == BookingStatus.pending).length;

    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = screenH * _kMapHeightFraction;

    final greeting = '${driverGreetingForNow(DateTime.now())}, $driverName';
    final bannerSubtitle = featured == null
        ? l10n.createTrip
        : pendingCount > 0
            ? 'You have $pendingCount booking request(s) waiting.'
            : 'Your next trip is ready when you are.';

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'driver_recurring',
            onPressed: () => context.push('/create-series'),
            child: const Icon(Icons.repeat),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'driver_newTrip',
            onPressed: () => context.push('/create-trip'),
            icon: const Icon(Icons.add),
            label: const Text('New Trip'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: AppColors.primary,
        edgeOffset: mapHeight * 0.45,
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
                      markers: _buildMarkers(_featuredTrip, _userLocation),
                      polylines: _buildPolylines(_featuredTrip, _directionRoute),
                      onTap: (_) {
                        final id = _featuredTrip?.id;
                        if (id != null && id.isNotEmpty) {
                          context.push('/trip-detail/$id');
                        }
                      },
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.menu_rounded),
                                  color: Colors.white,
                                  onPressed: () =>
                                      ShellDrawerScope.open(context),
                                ),
                                Expanded(
                                  child: Text(
                                    'Driver dashboard',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 88,
                      child: FloatingActionButton.small(
                        heroTag: 'driver_home_sos',
                        backgroundColor: AppColors.sosRed,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          final id = _featuredTrip?.id;
                          if (id != null) showEmergencyAlertFlow(context, id);
                        },
                        child: const Icon(Icons.emergency_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showBanner) ...[
                      DriverGreetingBanner(
                        title: greeting,
                        subtitle: bannerSubtitle,
                        onDismiss: () => setState(() => _showBanner = false),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_featuredTrip != null) ...[
                      DriverCurrentTripCard(
                        trip: _featuredTrip!,
                        bookings: tripBookings,
                        etaMinutes: etaMinutes,
                        distanceKm: distanceKm,
                        onOpen: () =>
                            context.push('/trip-detail/${_featuredTrip!.id}'),
                        onStart: _featuredTrip!.status == TripStatus.scheduled
                            ? () async {
                                final ok = await context
                                    .read<TripProvider>()
                                    .updateTripStatus(
                                      _featuredTrip!.id,
                                      TripStatus.inProgress,
                                    );
                                if (!context.mounted) return;
                                if (ok) {
                                  context
                                      .push('/tracking/${_featuredTrip!.id}');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.read<TripProvider>().error ??
                                            'Failed to start trip',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            : null,
                        onOpenTracking:
                            _featuredTrip!.status == TripStatus.inProgress
                                ? () => context
                                    .push('/tracking/${_featuredTrip!.id}')
                                : null,
                        onRequests: () => context
                            .push('/booking-requests/${_featuredTrip!.id}'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      l10n.scheduledTrips,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (tripProvider.loading && trips.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 36),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (trips.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.route,
                            size: 64, color: AppColors.textHintLight),
                        const SizedBox(height: 14),
                        Text(
                          'No trips yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a trip to start earning and accepting ride requests.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = trips[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DriverTripListCard(
                          trip: t,
                          l10n: l10n,
                          onTap: () => context.push('/trip-detail/${t.id}'),
                        ),
                      );
                    },
                    childCount: trips.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<MapMarker> _buildMarkers(TripModel? trip, LatLng? userLocation) {
  final markers = <MapMarker>[];
  if (trip != null && trip.routeCoordinates.isNotEmpty) {
    markers.add(MapMarker(
      position: LatLng(
        trip.routeCoordinates.first.lat,
        trip.routeCoordinates.first.lng,
      ),
    ));
    if (trip.routeCoordinates.length >= 2) {
      markers.add(MapMarker(
        position: LatLng(
          trip.routeCoordinates.last.lat,
          trip.routeCoordinates.last.lng,
        ),
        iconSize: 1.8,
      ));
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
