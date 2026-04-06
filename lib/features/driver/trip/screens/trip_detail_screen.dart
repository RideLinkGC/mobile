import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
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
        if (mounted) setState(() => _directionRoute = route);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.selectedTrip;
    final tripBookings = tripProvider.tripBookings;
    final isLoading = tripProvider.loading && trip == null && widget.tripId != null;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tripSchedule)),
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
        appBar: AppBar(title: Text(l10n.tripSchedule)),
        body: const Center(child: Text('Select a trip to view details')),
      );
    }

    final timeFmt = DateFormat.jm();
    final confirmedBookings =
        tripBookings.where((b) => b.status == BookingStatus.confirmed).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripSchedule),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusChip(status: trip.status),
            const SizedBox(height: 20),
            if (trip.routeCoordinates.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: GebetaMapWidget(
                    initialZoom: 13,
                    markers: _buildMapMarkers(trip),
                    polylines: _buildMapPolylines(trip),
                    showUserLocation: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: l10n.origin,
                    value: trip.origin,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: l10n.destination,
                    value: trip.destination,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: l10n.departureTime,
                    value: timeFmt.format(trip.departureTime),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.event_seat_outlined,
                    label: l10n.seats,
                    value: '${trip.seatsLeft} / ${trip.availableSeats}',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: l10n.pricePerSeat,
                    value: '${trip.pricePerSeat} ${l10n.etb}${l10n.perSeat}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Confirmed Passengers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...confirmedBookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                            fontWeight: FontWeight.w600,
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
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (booking.pickUpPoint != null || booking.dropOffPoint != null)
                              Text(
                                '${booking.pickUpPoint ?? '—'} → ${booking.dropOffPoint ?? '—'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (trip.status == TripStatus.scheduled) ...[
              AppButton(
                text: 'Start Trip',
                icon: Icons.play_arrow,
                onPressed: () => _handleUpdateStatus(TripStatus.inProgress),
              ),
              const SizedBox(height: 12),
            ],
            if (trip.status == TripStatus.inProgress) ...[
              AppButton(
                text: 'Complete Trip',
                icon: Icons.check_circle,
                onPressed: () => _handleUpdateStatus(TripStatus.completed),
              ),
              const SizedBox(height: 12),
            ],
            if (trip.status == TripStatus.scheduled || trip.status == TripStatus.inProgress) ...[
              AppButton(
                text: l10n.bookingRequests,
                icon: Icons.person_add_outlined,
                isOutlined: true,
                onPressed: () => context.push('/booking-requests/${trip.id}'),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Cancel Trip',
                icon: Icons.cancel_outlined,
                isOutlined: true,
                foregroundColor: AppColors.error,
                onPressed: () => _handleUpdateStatus(TripStatus.canceled),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPassengerDisplayName(BookingModel booking) {
    final name = booking.passengerName?.trim();
    final title = (name != null && name.isNotEmpty) ? name : 'Passenger';
    return '$title (${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''})';
  }

  List<MapMarker> _buildMapMarkers(dynamic trip) {
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

  List<MapPolyline> _buildMapPolylines(dynamic trip) {
    final rr = _directionRoute;
    if (rr != null && rr.polylinePoints.length >= 2) {
      return [
        MapPolyline(
          points: rr.polylinePoints
              .where((p) => p.length >= 2)
              .map((p) => LatLng(p[0], p[1]))
              .toList(),
          color: AppColors.primaryMapHex,
          width: 4,
        ),
      ];
    }
    if (trip.routeCoordinates.isEmpty) return [];
    final points = trip.routeCoordinates
        .map((c) => LatLng(c.lat, c.lng))
        .toList();
    return [MapPolyline(points: points, color: AppColors.primaryMapHex, width: 4)];
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
          color: color.withValues(alpha: 0.2),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
