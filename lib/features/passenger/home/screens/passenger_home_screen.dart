import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../driver/trip/providers/trip_provider.dart';
import '../../booking/data/passenger_bookings_mock.dart';
import '../../booking/widgets/passenger_booking_list_card.dart';

/// In-progress trip shown on the map (matches mock catalog `t1` for tracking/SOS).
const String _kCurrentTripId = 't1';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  LatLng? _userLocation;
  TripModel? _currentTrip;

  static const LatLng _fallbackPickup = LatLng(9.0192, 38.7525);
  static const LatLng _fallbackDropoff = LatLng(9.0300, 38.7800);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTrip();
    });
    _getUserLocation();
  }

  Future<void> _loadCurrentTrip() async {
    final trip =
        await context.read<TripProvider>().getTripById(_kCurrentTripId);
    if (mounted) setState(() => _currentTrip = trip);
  }

  Future<void> _getUserLocation() async {
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadCurrentTrip(),
      _getUserLocation(),
    ]);
  }

  void _openLiveTracking(BuildContext context) {
    context.push('/tracking/$_kCurrentTripId');
  }

  LatLng get _routeStart {
    final coords = _currentTrip?.routeCoordinates;
    if (coords != null && coords.isNotEmpty) {
      final c = coords.first;
      return LatLng(c.lat, c.lng);
    }
    return _fallbackPickup;
  }

  LatLng get _routeEnd {
    final coords = _currentTrip?.routeCoordinates;
    if (coords != null && coords.length >= 2) {
      final c = coords.last;
      return LatLng(c.lat, c.lng);
    }
    return _fallbackDropoff;
  }

  List<MapMarker> get _mapMarkers {
    final markers = <MapMarker>[
      MapMarker(position: _routeStart),
      MapMarker(position: _routeEnd, iconSize: 1.8),
    ];
    if (_userLocation != null) {
      markers.add(MapMarker(position: _userLocation!, iconSize: 1.4));
    }
    return markers;
  }

  List<MapPolyline> get _mapPolylines {
    return [
      MapPolyline(
        points: [_routeStart, _routeEnd],
        color: '#2196F3',
        width: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Guest';

    final trip = _currentTrip;
    final driverName = trip?.driverName ?? 'Abebe Kebede';
    final origin = trip?.origin ?? 'Bole, Airport Main Gate Area';
    final destination = trip?.destination ?? 'Megenagna, Megenagna Square';

    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = math.max(300.0, math.min(520.0, screenH * 0.44));

    final activeTrips = PassengerBookingsMock.active();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellMenuButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(l10n.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: mapHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GebetaMapWidget(
                        initialCenter: _userLocation ?? _routeStart,
                        initialZoom: 13.5,
                        showUserLocation: true,
                        interactive: true,
                        markers: _mapMarkers,
                        polylines: _mapPolylines,
                        onTap: (_) => _openLiveTracking(context),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).cardColor,
                          child: IconButton(
                            tooltip: l10n.passengerHomeOpenLiveView,
                            onPressed: () => _openLiveTracking(context),
                            icon: const Icon(Icons.fullscreen),
                          ),
                        ),
                      ),
                     ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.passengerHomeHi} $userName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.passengerHomeOnTheWay,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.passengerHomeEnRouteHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driverName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      if (trip != null && trip.vehicleModel != null)
                                        Text(
                                          trip.vehicleModel!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors
                                                    .textSecondaryLight,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$origin → $destination',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push(
                                      '/sos/$_kCurrentTripId',
                                    ),
                                    icon: Icon(
                                      Icons.emergency_outlined,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    label: Text(l10n.sos),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                        color: AppColors.error,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                               ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.passengerHomeActiveTrips,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.oneTimeTrip} · ${l10n.weekly} · ${l10n.monthly}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ...activeTrips.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PassengerBookingListCard(
                          item: item,
                          l10n: l10n,
                          onTap: () =>
                              context.push('/driver-detail/${item.tripId}'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/search'),
        tooltip: l10n.searchRide,
        child: const Icon(Icons.search),
      ),
    );
  }
}
