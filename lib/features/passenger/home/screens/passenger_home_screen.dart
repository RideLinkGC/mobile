import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../../../driver/trip/providers/trip_provider.dart';
import '../../../emergency/widgets/emergency_alert_sheet.dart';
import '../../booking/data/passenger_bookings_mock.dart';
import '../../booking/widgets/passenger_booking_list_card.dart';

/// In-progress trip shown on the map (matches mock catalog `t1` for tracking/SOS).
const String _kCurrentTripId = 't1';

/// Map height as a fraction of full device height (see design: ~70%).
const double _kMapHeightFraction = 0.7;

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey<GebetaMapWidgetState>();

  LatLng? _userLocation;
  TripModel? _currentTrip;
  RouteResult? _directionRoute;
  bool _showTravelBanner = true;

  late AnimationController _fabEntranceController;
  late AnimationController _fabPulseController;
  late Animation<double> _fabScale;
  late Animation<double> _fabOpacity;
  late Animation<double> _fabPulseScale;

  late AnimationController _bannerAnimController;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _bannerFade;

  static const LatLng _fallbackPickup = LatLng(9.0192, 38.7525);
  static const LatLng _fallbackDropoff = LatLng(9.0300, 38.7800);

  /// Shown only until directions load or if the API omits duration.
  static const int _kFallbackEtaMinutes = 8;

  @override
  void initState() {
    super.initState();
    _fabEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabEntranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _fabOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabEntranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _fabPulseScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(
        parent: _fabPulseController,
        curve: Curves.easeInOut,
      ),
    );
    _fabEntranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _fabPulseController.repeat(reverse: true);
      }
    });
    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bannerAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _bannerFade = CurvedAnimation(
      parent: _bannerAnimController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().ensureLocationPermissionRequested();
      _loadCurrentTrip();
      if (mounted) _fabEntranceController.forward();
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _bannerAnimController.forward();
      });
    });
    _getUserLocation();
  }

  @override
  void dispose() {
    _fabEntranceController.dispose();
    _fabPulseController.dispose();
    _bannerAnimController.dispose();
    super.dispose();
  }

  Future<void> _dismissTravelBanner() async {
    await _bannerAnimController.reverse();
    if (mounted) setState(() => _showTravelBanner = false);
  }

  Future<void> _loadCurrentTrip() async {
    final trip =
        await context.read<TripProvider>().getTripById(_kCurrentTripId);
    if (!mounted) return;
    setState(() => _currentTrip = trip);
    await _loadDirectionRoute();
  }

  Future<void> _loadDirectionRoute() async {
    final o = _routeStart;
    final d = _routeEnd;
    final maps = context.read<GebetaMapsService>();
    final route = await maps.getRoute(
      originLat: o.latitude,
      originLng: o.longitude,
      destLat: d.latitude,
      destLng: d.longitude,
    );
    if (!mounted) return;
    setState(() => _directionRoute = route);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
  }

  void _fitMapToRoute() {
    final state = _mapKey.currentState;
    if (state == null) return;

    final points = <LatLng>[];
    final rr = _directionRoute;
    if (rr != null && rr.polylinePoints.length >= 2) {
      for (final p in rr.polylinePoints) {
        if (p.length >= 2) points.add(LatLng(p[0], p[1]));
      }
    } else {
      points.addAll([_routeStart, _routeEnd]);
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

  Future<void> _getUserLocation() async {
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
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
    final rr = _directionRoute;
    if (rr != null && rr.polylinePoints.length >= 2) {
      return [
        MapPolyline(
          points: rr.polylinePoints
              .where((p) => p.length >= 2)
              .map((p) => LatLng(p[0], p[1]))
              .toList(),
          color: AppColors.primaryMapHex,
          width: 5,
        ),
      ];
    }
    return [
      MapPolyline(
        points: [_routeStart, _routeEnd],
        color: AppColors.primaryMapHex,
        width: 5,
      ),
    ];
  }

  String _shortDriverName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return name;
    if (parts.length == 1) return parts.first;
    final last = parts.last;
    final initial = last.isNotEmpty ? '${last[0]}.' : '';
    return '${parts.first} $initial'.trim();
  }

  String _vehicleSubtitle(TripModel? trip) {
    final model = trip?.vehicleModel ?? 'Toyota Prius';
    final plate = trip?.vehiclePlate ?? 'AA 2-34567';
    return '$model • $plate';
  }

  /// Minutes from Gebeta `timetaken` (via [RouteResult.durationMinutes]).
  int get _etaMinutes {
    final m = _directionRoute?.durationMinutes;
    if (m == null || m <= 0) return _kFallbackEtaMinutes;
    return m.round().clamp(1, 24 * 60);
  }

  /// Kilometers from Gebeta `totalDistance` (via [RouteResult.distanceKm]).
  double? get _routeDistanceKm {
    final km = _directionRoute?.distanceKm;
    if (km == null || km <= 0) return null;
    return km;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trip = _currentTrip;
    final driverName = trip?.driverName ?? 'Abebe Kebede';
    final rating = trip?.driverRating ?? 4.9;
    final origin = trip?.origin ?? 'Bole, Airport Main Gate';
    final destination = trip?.destination ?? 'Megenagna Square';
    final price = trip?.pricePerSeat ?? 45.0;
    final seatCount = trip?.vehicleSeats ?? trip?.availableSeats ?? 4;

    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = screenH * _kMapHeightFraction;

    final etaTime = DateFormat.jm().format(
      DateTime.now().add(Duration(minutes: _etaMinutes)),
    );

    final activeTrips = PassengerBookingsMock.active();

    final surfaceCard = colorScheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.94 : 1,
    );

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? AppColors.darkBackground
          : colorScheme.surface,
      floatingActionButton: AnimatedBuilder(
        animation: Listenable.merge([
          _fabEntranceController,
          _fabPulseController,
        ]),
        builder: (context, child) {
          final entrance = _fabScale.value;
          final pulse = _fabEntranceController.status == AnimationStatus.completed
              ? _fabPulseScale.value
              : 1.0;
          return Transform.scale(
            scale: entrance * pulse,
            child: FadeTransition(
              opacity: _fabOpacity,
              child: child,
            ),
          );
        },
        child: FloatingActionButton(
          heroTag: 'passenger_home_sos',
          tooltip: l10n.sos,
          onPressed: () =>
              showEmergencyAlertFlow(context, _kCurrentTripId),
          backgroundColor: AppColors.sosRed,
          foregroundColor: Colors.white,
          elevation: 6,
          child: const Icon(Icons.emergency_rounded, size: 28),
        ),
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
                      initialCenter: _userLocation ?? _routeStart,
                      initialZoom: 13.5,
                      showUserLocation: true,
                      interactive: true,
                      markers: _mapMarkers,
                      polylines: _mapPolylines,
                      onTap: (_) => _openLiveTracking(context),
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
                                    l10n.passengerDashboardTitle,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
                      left: 0,
                      right: 0,
                      bottom: 20,
                      child: Center(
                        child: Material(
                          color: AppColors.primary.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          elevation: 4,
                          child: InkWell(
                            onTap: () => _openLiveTracking(context),
                            borderRadius: BorderRadius.circular(28),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.passengerDashboardMinutesAway(
                                      _etaMinutes,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 88,
                      child: FloatingActionButton.small(
                        heroTag: 'passenger_home_search',
                        backgroundColor: colorScheme.surface,
                        foregroundColor: AppColors.primary,
                        elevation: 4,
                        onPressed: () => context.push('/search'),
                        child: const Icon(Icons.search_rounded),
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
                    if (_showTravelBanner) ...[
                      SlideTransition(
                        position: _bannerSlide,
                        child: FadeTransition(
                          opacity: _bannerFade,
                          child: _PleasantJourneyBanner(
                            message: l10n.passengerDashboardTravelBanner,
                            onDismiss: _dismissTravelBanner,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Material(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(22),
                      elevation: theme.brightness == Brightness.dark ? 0 : 1,
                      shadowColor: Colors.black26,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: trip?.driverImage != null &&
                                              trip!.driverImage!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: trip.driverImage!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  _avatarFallback(
                                                driverName,
                                                64,
                                              ),
                                            )
                                          : _avatarFallback(driverName, 64),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: -6,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons.star_rounded,
                                                color: AppColors.ratingStar,
                                                size: 13,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _shortDriverName(driverName),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _vehicleSubtitle(trip),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  l10n.passengerDashboardEtaLabel(etaTime),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TimelineRail(theme: theme),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n.passengerDashboardPickup}: $origin',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        '${l10n.passengerDashboardDropoff}: $destination',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _SpecChip(
                                  label: l10n.passengerDashboardSeatsCount(
                                    seatCount,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_routeDistanceKm != null) ...[
                                  _SpecChip(
                                    label:
                                        '${_routeDistanceKm!.toStringAsFixed(1)} ${l10n.km}',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                _SpecChip(label: l10n.passengerDashboardAcOn),
                                const Spacer(),
                                Text(
                                  '${price.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.push('/rating/$_kCurrentTripId'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.passengerDashboardIveArrived,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_rounded, size: 22),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.passengerHomeActiveTrips,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.oneTimeTrip} · ${l10n.weekly} · ${l10n.monthly}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = activeTrips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PassengerBookingListCard(
                        item: item,
                        l10n: l10n,
                        onTap: () =>
                            context.push('/driver-detail/${item.tripId}'),
                      ),
                    );
                  },
                  childCount: activeTrips.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name, double size) {
    final initial =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PleasantJourneyBanner extends StatelessWidget {
  const _PleasantJourneyBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final List<Color> gradientColors;
    final Color borderColor;
    final List<BoxShadow> boxShadow;
    final Color watermarkColor;
    if (isDark) {
      final base = AppColors.darkBackground;
      gradientColors = [
        Color.lerp(base, const Color(0xFFFFFFFF), 0.045)!,
        Color.lerp(base, const Color(0xFFFFFFFF), 0.028)!,
        Color.lerp(base, const Color(0xFFFFFFFF), 0.055)!,
      ];
      borderColor = Colors.white.withValues(alpha: 0.09);
      boxShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 18,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];
      watermarkColor = Colors.white.withValues(alpha: 0.028);
    } else {
      final surf = scheme.surface;
      gradientColors = [
        Color.lerp(surf, scheme.onSurface, 0.04)!,
        Color.lerp(surf, scheme.onSurface, 0.025)!,
        Color.lerp(surf, scheme.onSurface, 0.055)!,
      ];
      borderColor = scheme.outline.withValues(alpha: 0.22);
      boxShadow = [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
      watermarkColor = scheme.onSurface.withValues(alpha: 0.04);
    }

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.0, 0.52, 1.0],
          ),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: boxShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -24,
                child: Icon(
                  Icons.route_rounded,
                  size: 96,
                  color: watermarkColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.9),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : scheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.route_rounded,
                        color: isDark
                            ? AppColors.primaryLight.withValues(alpha: 0.95)
                            : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.92)
                              : scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : scheme.onSurface.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final lineColor = theme.colorScheme.outline.withValues(alpha: 0.45);
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
              color: theme.colorScheme.surface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SizedBox(
              height: 28,
              child: CustomPaint(
                painter: _DashedLinePainter(color: lineColor),
                size: const Size(2, 28),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const gap = 3.0;
    double y = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final cx = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(cx, y), Offset(cx, math.min(y + dash, size.height)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
