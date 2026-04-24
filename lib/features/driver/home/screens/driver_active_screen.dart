import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/core/widgets/tab_view.dart';
import 'package:ridelink/core/utils/get_active_trip.dart';
import 'package:ridelink/features/driver/common/driver_app_bar.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../emergency/widgets/emergency_alert_sheet.dart';
import '../../trip/providers/trip_provider.dart';

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
  
  RouteResult? _directionRoute;
  final TextEditingController _messageController = TextEditingController();

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveTrip() async {
    final tripProvider = context.read<TripProvider>();
    await tripProvider.loadDriverTrips();

    if (!mounted) return;
    final active = getActiveTrip(List<TripModel>.of(tripProvider.driverTrips));
    setState(() {
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

  Future<void> _approveAllRequests(String tripId) async {
    final tripProvider = context.read<TripProvider>();
    final pending = tripProvider.tripBookings
        .where((b) => b.status == BookingStatus.pending)
        .toList(growable: false);
    for (final b in pending) {
      await tripProvider.acceptBooking(b.id);
    }
    await tripProvider.loadTripBookings(tripId);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _cancelTrip(String tripId) async {
    final tripProvider = context.read<TripProvider>();
    await tripProvider.updateTripStatus(tripId, TripStatus.canceled);
    await tripProvider.loadDriverTrips();
    await tripProvider.loadTripBookings(tripId);
    if (!mounted) return;
    await _loadActiveTrip();
  }

  void _fitMapToRoute() {
    final state = _mapKey.currentState;
    if (state == null) return;

    final points = <LatLng>[];
    final tripProvider = context.read<TripProvider>();
    final trip = getActiveTrip(List<TripModel>.of(tripProvider.driverTrips));
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

  int selectedTab=0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tripProvider = context.watch<TripProvider>();

    final activeTrip = getActiveTrip(List<TripModel>.of(tripProvider.driverTrips));
    final tripBookings = tripProvider.tripBookings;
    final approvedBookings =
        tripBookings.where((b) => b.status == BookingStatus.confirmed).toList();
    final timeFmt = DateFormat.jm();
    final rr = _directionRoute;
    final etaMinutes = rr != null && rr.durationMinutes > 0
        ? rr.durationMinutes.round().clamp(1, 24 * 60)
        : null;
    final distanceKm = rr != null && rr.distanceKm > 0 ? rr.distanceKm : null;

    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = screenH * _kMapHeightFraction;

    return Scaffold(
        appBar: driverAppBarWitDrawer(context, l10n.activeTrip, true),
      backgroundColor: theme.brightness == Brightness.dark
          ? AppColors.darkBackground
          : scheme.surface,
      floatingActionButton: FloatingActionButton(
              heroTag: 'driver_active_sos',
              tooltip: l10n.sos,
              onPressed: activeTrip == null
                  ? null
                  : () => showEmergencyAlertFlow(context, activeTrip.id),
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
                      markers: _buildMarkers(activeTrip, _userLocation),
                      polylines: _buildPolylines(activeTrip, _directionRoute),
                      onTap: (_) {
                        final id = activeTrip?.id ?? '';
                        if (id.isNotEmpty) {
                          context.push('/tracking/$id');
                        }
                      },
                    ),
                    if (activeTrip != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: _ActiveRouteOverlayCard(trip: activeTrip),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: RideTabView(
                  count: 3,
                 labels: ["Trip Info","Passengers","Messages"], 
                 selectedTab: selectedTab,
                  onClick: (index){
                    setState(() {
                      selectedTab=index;
                    });
                  }),
                      
              ),
            ),
            if (activeTrip == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    child: Text(
                      'No active trip',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (selectedTab == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: _TripInfoDetails(
                    trip: activeTrip,
                    bookingCount: tripBookings.length,
                    approvedCount: approvedBookings.length,
                    etaMinutes: etaMinutes,
                    distanceKm: distanceKm,
                    onApproveAll: () => _approveAllRequests(activeTrip.id),
                    onCancelTrip: () => _cancelTrip(activeTrip.id),
                  ),
                ),
              )
            else if (selectedTab == 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final booking = approvedBookings[index];
                      final name = (booking.passengerName?.trim().isNotEmpty ?? false)
                          ? booking.passengerName!.trim()
                          : 'Passenger';
                      final subtitle =
                          '${booking.pickUpPoint ?? '—'} → ${booking.dropOffPoint ?? '—'}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.25),
                            child: Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            '$name (${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            booking.tripDepartureTime != null
                                ? timeFmt.format(booking.tripDepartureTime!)
                                : '',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: approvedBookings.length,
                  ),
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'No message',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Write a message…',
                          filled: true,
                          fillColor: scheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => FocusScope.of(context).unfocus(),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Send'),
                      ),
                      const SizedBox(height: 120),
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

class _TripInfoDetails extends StatelessWidget {
  final TripModel trip;
  final int bookingCount;
  final int approvedCount;
  final int? etaMinutes;
  final double? distanceKm;
  final VoidCallback onApproveAll;
  final VoidCallback onCancelTrip;

  const _TripInfoDetails({
    required this.trip,
    required this.bookingCount,
    required this.approvedCount,
    this.etaMinutes,
    this.distanceKm,
    required this.onApproveAll,
    required this.onCancelTrip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeFmt = DateFormat.jm();
    final dateFmt = DateFormat('MMM d, yyyy');

    final eta = (etaMinutes != null && etaMinutes! > 0)
        ? '${etaMinutes!} mins'
        : '-- mins';
    final dist = (distanceKm != null && distanceKm! > 0)
        ? '${distanceKm!.toStringAsFixed(1)} ${l10n.km}'
        : (trip.distanceKm > 0
            ? '${trip.distanceKm.toStringAsFixed(1)} ${l10n.km}'
            : '-- ${l10n.km}');

    final bookedSeats = trip.bookedSeats;
    final seatsLeft = trip.seatsLeft;
    final availableSeats = trip.availableSeats;

    final totalPassengers = bookingCount; // total bookings for this trip
    final approvedPassengers = approvedCount;
    final pendingPassengers = math.max(0, totalPassengers - approvedPassengers);

    final progress = availableSeats <= 0
        ? 0.0
        : (bookedSeats / availableSeats).clamp(0.0, 1.0);
    final seatsSummary = '$bookedSeats/$availableSeats Seats';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Start Date',
                value: dateFmt.format(trip.departureTime),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.schedule_rounded,
                label: 'Start Time',
                value: timeFmt.format(trip.departureTime),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.timelapse_rounded,
                label: 'Est. Time',
                value: eta,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.route_rounded,
                label: 'Distance',
                value: dist,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Seat Inventory',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          ),
          _InfoTile(icon: Icons.price_change, label: "Price per Seat",
           value: '${trip.pricePerSeat.toStringAsFixed(0)} ETB',),

        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Capacity Status',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    seatsSummary,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SeatStatTile(
                      label: 'Total Seat',
                      value: availableSeats.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SeatStatTile(
                      label: 'Booked Seat',
                      value: bookedSeats.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SeatStatTile(
                      label: 'Availble Seat',
                      value: seatsLeft.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'Manifest',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _ManifestMetric(
                  title: 'Total Passengers',
                  value: '$totalPassengers requests',
                ),
              ),
             
              Expanded(
                child: _ManifestMetric(
                  title: 'Approved',
                  value: '$approvedPassengers confirmed',
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: pendingPassengers > 0 ? onApproveAll : null,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Approve All Requests'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onCancelTrip,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Trip'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            foregroundColor: scheme.onSurface,
            side: BorderSide(color: scheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveRouteOverlayCard extends StatelessWidget {
  final TripModel trip;
  const _ActiveRouteOverlayCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String statusLabel;
    Color statusColor;
    switch (trip.status) {
      case TripStatus.scheduled:
        statusLabel = 'Scheduled';
        statusColor = AppColors.info;
        break;
      case TripStatus.inProgress:
        statusLabel = 'In Progress';
        statusColor = AppColors.success;
        break;
      case TripStatus.completed:
        statusLabel = 'Completed';
        statusColor = AppColors.textSecondaryLight;
        break;
      case TripStatus.canceled:
        statusLabel = 'Canceled';
        statusColor = AppColors.error;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ROUTE',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.origin} → ${trip.destination}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
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

class _SeatStatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _SeatStatTile({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = highlighted ? Colors.white : scheme.onSurface;
    final sub = highlighted ? Colors.white70 : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 1,
            spreadRadius: 1,
            color: scheme.onSurface.withAlpha(20)
          )
        ],
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: BoxBorder.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: sub,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManifestMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _ManifestMetric({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}


