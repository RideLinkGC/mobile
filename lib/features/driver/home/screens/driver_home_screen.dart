import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/features/driver/common/driver_app_bar.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../passenger/booking/models/booking_model.dart';
import '../../trip/providers/trip_provider.dart';
import '../widgets/driver_current_trip_card.dart';
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
    authProvider.user?.name ?? 'Driver';
    final trips = tripProvider.driverTrips;
    final now = DateTime.now();

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
    tripBookings.where((b) => b.status == BookingStatus.pending).length;
    final featuredBookings = _featuredTrip == null
        ? const <BookingModel>[]
        : tripBookings
            .where((b) => b.tripId == _featuredTrip!.id)
            .toList(growable: false);

    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = screenH * _kMapHeightFraction;

    final scheduledTrips = trips
        .where((t) => t.status == TripStatus.scheduled)
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

    return Scaffold(
      appBar: driverAppBarWitDrawer(context, l10n.home, true),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'driver_newTrip',
        onPressed: () => context.push('/create-trip'),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                   
                    if (_featuredTrip != null) ...[
                      DriverCurrentTripCard(
                        trip: _featuredTrip!,
                        bookings: featuredBookings,
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
                    _ScheduledTripsTabbedSection(
                      title: l10n.scheduledTrips,
                      now: now,
                      loading: tripProvider.loading && trips.isEmpty,
                      trips: scheduledTrips,
                      onOpenTrip: (id) => context.push('/trip-detail/$id'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ScheduleFilter { today, week, month, all }

List<TripModel> _filterScheduledTrips(
  List<TripModel> trips, {
  required DateTime now,
  required _ScheduleFilter filter,
}) {
  if (filter == _ScheduleFilter.all) return trips;

  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  bool inRange(DateTime d, DateTime start, DateTime end) =>
      !d.isBefore(start) && d.isBefore(end);

  switch (filter) {
    case _ScheduleFilter.today:
      return trips.where((t) => inRange(t.departureTime, todayStart, todayEnd)).toList();
    case _ScheduleFilter.week:
      final weekday = todayStart.weekday; // Mon=1..Sun=7
      final weekStart = todayStart.subtract(Duration(days: weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return trips.where((t) => inRange(t.departureTime, weekStart, weekEnd)).toList();
    case _ScheduleFilter.month:
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd =
          (now.month == 12) ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      return trips.where((t) => inRange(t.departureTime, monthStart, monthEnd)).toList();
    case _ScheduleFilter.all:
      return trips;
  }
}

class _ScheduledTripsTabbedSection extends StatefulWidget {
  const _ScheduledTripsTabbedSection({
    required this.title,
    required this.now,
    required this.loading,
    required this.trips,
    required this.onOpenTrip,
  });

  final String title;
  final DateTime now;
  final bool loading;
  final List<TripModel> trips;
  final ValueChanged<String> onOpenTrip;

  @override
  State<_ScheduledTripsTabbedSection> createState() =>
      _ScheduledTripsTabbedSectionState();
}

class _ScheduledTripsTabbedSectionState extends State<_ScheduledTripsTabbedSection>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    // Default selected tab: "All" (index 0).
    _controller = TabController(length: 4, vsync: this, initialIndex: 0);
    _controller.addListener(() {
      if (!mounted) return;
      // Rebuild when index changes (tap/animate).
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final all = widget.trips;
    final today = _filterScheduledTrips(
      all,
      now: widget.now,
      filter: _ScheduleFilter.today,
    );
    final week = _filterScheduledTrips(
      all,
      now: widget.now,
      filter: _ScheduleFilter.week,
    );
    final month = _filterScheduledTrips(
      all,
      now: widget.now,
      filter: _ScheduleFilter.month,
    );

    // Order must match TabBar order: All, Today, This Week, This Month
    final List<({List<TripModel> trips, String emptyTitle})> tabs = [
      (trips: all, emptyTitle: 'No scheduled trips'),
      (trips: today, emptyTitle: 'No trips scheduled for today'),
      (trips: week, emptyTitle: 'No trips scheduled this week'),
      (trips: month, emptyTitle: 'No trips scheduled this month'),
    ];

    final active = tabs[_controller.index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _CountBadge(count: widget.trips.length),
          ],
        ),
        const SizedBox(height: 10),
        TabBar(
          
          controller: _controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 1,
          dividerColor: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          indicatorWeight: 1,
          // Compact, professional spacing (no huge gaps).
          labelPadding: const EdgeInsets.only(right: 1),
          padding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          indicatorColor: Theme.of(context).colorScheme.primary,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          // indicator: BoxDecoration(
          //   color: const Color.fromARGB(255, 154, 197, 204),
          //   borderRadius: BorderRadius.circular(50),
          // ),
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant.withValues(alpha: 0.9),
          labelStyle:
              theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          tabs: [
            _CompactPillTab(label: 'All', count: all.length),
            _CompactPillTab(label: 'Today', count: today.length),
            _CompactPillTab(label: 'This Week', count: week.length),
            _CompactPillTab(label: 'This Month', count: month.length),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else
          _TripsTabBody(
            l10n: l10n,
            trips: active.trips,
            emptyTitle: active.emptyTitle,
            onOpenTrip: widget.onOpenTrip,
          ),
      ],
    );
  }
}

class _CompactPillTab extends StatelessWidget {
  const _CompactPillTab({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Text(
              '($count)',
            ),
          ],
        ),
      ),
    );
  }
}

class _TripsTabBody extends StatelessWidget {
  const _TripsTabBody({
    required this.l10n,
    required this.trips,
    required this.emptyTitle,
    required this.onOpenTrip,
  });

  final AppLocalizations l10n;
  final List<TripModel> trips;
  final String emptyTitle;
  final ValueChanged<String> onOpenTrip;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _ScheduledEmptyState(title: emptyTitle);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = trips[index];
        return DriverTripListCard(
          trip: t,
          l10n: l10n,
          onTap: () => onOpenTrip(t.id),
        );
      },
    );
  }
}

class _ScheduledEmptyState extends StatelessWidget {
  const _ScheduledEmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.event_note_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a trip to start receiving booking requests.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// Note: Map helpers removed (this screen currently doesn't render a map).
