import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/core/widgets/ride_button.dart';
import 'package:ridelink/core/widgets/tab_view.dart';
import 'package:ridelink/features/driver/common/driver_app_bar.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chat/providers/chat_provider.dart';
import '../../../passenger/booking/models/booking_model.dart';
import '../providers/trip_provider.dart';

class TripDetailScreen extends StatefulWidget {
  final String? tripId;

  const TripDetailScreen({super.key, this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  RouteResult? _directionRoute;
  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey<GebetaMapWidgetState>();
  int selectedTab=0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tripId = widget.tripId;
      if (tripId == null || tripId.isEmpty) return;

      final tripProvider = context.read<TripProvider>();
      final mapsService = context.read<GebetaMapsService>();

      await tripProvider.getTripById(tripId);
      await tripProvider.loadTripBookings(tripId);
      if (!mounted) return;

      final trip = tripProvider.selectedTrip;
      if (trip != null && trip.routeCoordinates.length >= 2) {
        final first = trip.routeCoordinates.first;
        final last = trip.routeCoordinates.last;
        final route = await mapsService.getRoute(
          originLat: first.lat,
          originLng: first.lng,
          destLat: last.lat,
          destLng: last.lng,
        );
        if (mounted) {
          setState(() => _directionRoute = route);
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
        }
      }
    });
  }

  void _fitMapToRoute() {
    final state = _mapKey.currentState;
    if (state == null) return;
    final trip = context.read<TripProvider>().selectedTrip;
    if (trip == null) return;

    final points = <LatLng>[];
    final rr = _directionRoute;
    if (rr != null && rr.polylinePoints.length >= 2) {
      for (final p in rr.polylinePoints) {
        if (p.length >= 2) points.add(LatLng(p[0], p[1]));
      }
    } else if (trip.routeCoordinates.length >= 2) {
      points.addAll(trip.routeCoordinates.map((c) => LatLng(c.lat, c.lng)));
    } else {
      return;
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

  Future<void> _handleUpdateStatus(TripStatus status) async {
    final tripId = widget.tripId;
    if (tripId == null) return;

    final provider = context.read<TripProvider>();
    if (status == TripStatus.inProgress) {
      final allow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start trip now?'),
          content: const Text(
            'Starting the trip will notify confirmed passengers and begin live tracking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Start'),
            ),
          ],
        ),
      );
      if (allow != true) return;
    }
    final success = await provider.updateTripStatus(tripId, status);
    if (!mounted) return;

    if (success) {
      await provider.getTripById(tripId);
      if (!mounted) return;
      if (status == TripStatus.inProgress) {
        context.push('/tracking/$tripId');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update trip status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openChatForBooking(BookingModel booking) async {
    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    await auth.syncConvexAuth();
    final userId = auth.user?.id;
    if (userId != null && userId.isNotEmpty) {
      chatProvider.setUserId(userId);
    }
    final conversationId = await chatProvider.getConversationIdByBooking(booking.id);
    if (!mounted) return;
    if (conversationId != null && conversationId.isNotEmpty) {
      context.push('/chat/$conversationId');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat will be available once the request is accepted.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.selectedTrip;
    final tripBookings = tripProvider.tripBookings;
    final isLoading = tripProvider.loading && trip == null && widget.tripId != null;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.tripSchedule)
          ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (trip == null && widget.tripId != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tripSchedule)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textHintLight),
              const SizedBox(height: 16),
              Text(
                'Trip not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: driverAppBarWitDrawer(context, l10n.tripSchedule, false),
        body: const Center(child: Text('Select a trip to view details')),
      );
    }

    final timeFmt = DateFormat.jm();
    final confirmedBookings =
        tripBookings.where((b) => b.status == BookingStatus.confirmed).toList();
    final pendingCount =
        tripBookings.where((b) => b.status == BookingStatus.pending).length;
    final rr = _directionRoute;
    final etaMinutes = rr != null && rr.durationMinutes > 0
        ? rr.durationMinutes.round().clamp(1, 24 * 60)
        : null;
    final distanceKm = rr != null && rr.distanceKm > 0 ? rr.distanceKm : null;

    return Scaffold(
        appBar: driverAppBarWitDrawer(context, l10n.tripSchedule, false),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GebetaMapWidget(
                    key: _mapKey,
                    initialZoom: 13,
                    markers: _buildMapMarkers(trip),
                    polylines: _buildMapPolylines(trip),
                    showUserLocation: false,
                    interactive: true,
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
                  _StatusChip(status: trip.status),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.origin} → ${trip.destination}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.schedule,
                              label: timeFmt.format(trip.departureTime),
                            ),
                            _InfoChip(
                              icon: Icons.timelapse_rounded,
                              label: etaMinutes != null ? '$etaMinutes min' : '-- min',
                            ),
                            _InfoChip(
                              icon: Icons.route_rounded,
                              label: distanceKm != null
                                  ? '${distanceKm.toStringAsFixed(1)} ${l10n.km}'
                                  : '-- ${l10n.km}',
                            ),
                            _InfoChip(
                              icon: Icons.event_seat_outlined,
                              label: '${trip.seatsLeft} / ${trip.availableSeats} ${l10n.seats}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _Pill(
                              label: 'Confirmed',
                              value: confirmedBookings.length.toString(),
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            _Pill(
                              label: 'Pending',
                              value: pendingCount.toString(),
                              color: AppColors.warning,
                            ),
                            const Spacer(),
                            Text(
                              '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                        if (trip.status == TripStatus.scheduled) ...[
                    Flexible(
                      child: RideLinkButton(
                        text: 'Start Trip',
                        isOutlined: true,
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        icon: Icons.play_arrow,
                        onPressed: () => _handleUpdateStatus(TripStatus.inProgress),
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                  if (trip.status == TripStatus.inProgress) ...[
                    Flexible(
                      child: RideLinkButton(
                        text: 'Complete Trip',
                        icon: Icons.check_circle,
                        isOutlined: true,
                        onPressed: () => _handleUpdateStatus(TripStatus.completed),
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                  if (trip.status == TripStatus.scheduled ||
                      trip.status == TripStatus.inProgress) ...[
                    
                    Flexible(
                      child: RideLinkButton(
                        text: 'Cancel Trip',
                        icon: Icons.cancel_outlined,
                        isOutlined: false,
                        foregroundColor: AppColors.error,
                        onPressed: () => _handleUpdateStatus(TripStatus.canceled),
                      ),
                    ),
                  ],
                    ],
                  ),
                   SizedBox(height: 35,),
                  RideTabView(
                    count: 2,
                    labels: ["Passengers","Booking request"],
                    selectedTab: selectedTab,
                    onClick: (index){
                      setState(() {
                        selectedTab=index;
                      });
                    },
                  ),
                 
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final booking = confirmedBookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                            child: Text(
                              _getPassengerDisplayName(booking).substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPassengerDisplayName(booking),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.pickUpPoint ?? '—\n'} → ${booking.dropOffPoint ?? '—'}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openChatForBooking(booking),
                            icon: const Icon(Icons.chat_bubble_outline),
                            tooltip: 'Chat',
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: confirmedBookings.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPassengerDisplayName(BookingModel booking) {
    final name = booking.passengerName?.trim();
    final title = (name != null && name.isNotEmpty) ? name : 'Passenger';
    return '$title (${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''})';
  }

  List<MapMarker> _buildMapMarkers(TripModel trip) {
    final markers = <MapMarker>[];
    if (trip.routeCoordinates.isNotEmpty) {
      markers.add(MapMarker(
        position: LatLng(trip.routeCoordinates.first.lat, trip.routeCoordinates.first.lng),
      ));
      if (trip.routeCoordinates.length > 1) {
        markers.add(MapMarker(
          position: LatLng(trip.routeCoordinates.last.lat, trip.routeCoordinates.last.lng),
        ));
      }
    }
    return markers;
  }

  List<MapPolyline> _buildMapPolylines(TripModel trip) {
    final rr = _directionRoute;
    if (rr != null && rr.polylinePoints.length >= 2) {
      final routePoints = rr.polylinePoints
          .where((p) => p.length >= 2)
          .map<LatLng>((p) {
            final lat = (p[0] as num).toDouble();
            final lng = (p[1] as num).toDouble();
            return LatLng(lat, lng);
          })
          .toList(growable: false);
      if (routePoints.length < 2) return [];
      return [
        MapPolyline(
          points: routePoints,
          color: AppColors.primaryMapHex,
          width: 4,
        ),
      ];
    }
    if (trip.routeCoordinates.isEmpty) return [];
    final points = trip.routeCoordinates
        .map<LatLng>((c) => LatLng(c.lat, c.lng))
        .toList(growable: false);
    return [MapPolyline(points: points, color: AppColors.primaryMapHex, width: 4)];
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: scheme.surface.withValues(alpha: 0.1),
            blurRadius: 1,
            spreadRadius: 1
          )
        ],
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color:Colors.grey),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Pill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TripStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TripStatus.scheduled:
        color = AppColors.info;
        label = 'Scheduled';
        break;
      case TripStatus.inProgress:
        color = AppColors.success;
        label = 'In Progress';
        break;
      case TripStatus.completed:
        color = AppColors.textSecondaryLight;
        label = 'Completed';
        break;
      case TripStatus.canceled:
        color = AppColors.error;
        label = 'Canceled';
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
