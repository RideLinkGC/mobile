import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../driver/trip/providers/trip_provider.dart';
import '../../../feedback/providers/feedback_provider.dart';

class DriverDetailScreen extends StatefulWidget {
  final String tripId;

  const DriverDetailScreen({super.key, required this.tripId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final trip = await context.read<TripProvider>().getTripById(widget.tripId);
    if (mounted && trip != null) {
      await context.read<FeedbackProvider>().loadFeedbackForUser(trip.driverId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.watch<TripProvider>();
    final feedbackProvider = context.watch<FeedbackProvider>();
    final trip = tripProvider.selectedTrip;
    final reviews = feedbackProvider.ratings;
    final isLoading = tripProvider.loading && trip == null;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trips)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trips)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tripProvider.error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Try Again',
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final polyline = trip.routeCoordinates.isNotEmpty
        ? trip.routeCoordinates
            .map((c) => LatLng(c.lat, c.lng))
            .toList()
        : <LatLng>[];
    final originLatLng = polyline.isNotEmpty
        ? polyline.first
        : const LatLng(9.0192, 38.7525);
    final destLatLng = polyline.isNotEmpty
        ? polyline.last
        : const LatLng(9.0300, 38.7800);
    final mapCenter = polyline.isNotEmpty
        ? polyline[polyline.length ~/ 2]
        : originLatLng;

    final dateFormat = DateFormat.jm();
    final departureFormatted = dateFormat.format(trip.departureTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip.origin} → ${trip.destination}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: GebetaMapWidget(
                  initialCenter: mapCenter,
                  initialZoom: 13,
                  interactive: false,
                  markers: [
                    MapMarker(position: originLatLng),
                    MapMarker(position: destLatLng),
                  ],
                  polylines: polyline.length >= 2
                      ? [
                          MapPolyline(
                            points: polyline,
                            color: '#188AEC',
                            width: 4,
                          ),
                        ]
                      : [],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (trip.distanceKm > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _InfoChip(
                      icon: Icons.straighten,
                      label: '${trip.distanceKm.toStringAsFixed(1)} km',
                    ),
                  ],
                ),
              ),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driverName ?? 'Driver',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        AppRatingWidget(
                          rating: (trip.driverRating ?? 0).toDouble(),
                          size: 18,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${trip.vehicleModel ?? ''} (${trip.vehiclePlate ?? ''})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${trip.vehicleSeats ?? 0} ${l10n.seats}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Details',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${trip.origin} → ${trip.destination}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.departureTime}: $departureFormatted',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.pricePerSeat}: ${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat_outlined,
                        size: 18,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.seatsLeft} ${l10n.seats}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (feedbackProvider.loadingFeedback)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No reviews yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              )
            else
              ...reviews.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppRatingWidget(
                              rating: (r.rating ?? 0).toDouble(),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              r.createdAt != null
                                  ? DateFormat.yMMMd().format(r.createdAt!)
                                  : '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.comment ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.requestBooking,
              onPressed: () => context.push('/booking-confirm/${widget.tripId}'),
            ),
            if (trip.seriesId != null) ...[
              const SizedBox(height: 12),
              AppButton(
                text: l10n.subscribe,
                onPressed: () =>
                    context.push('/subscription/${widget.tripId}'),
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
