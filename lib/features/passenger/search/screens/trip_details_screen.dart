import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../passenger/booking/providers/booking_provider.dart';
import '../../../driver/trip/providers/trip_provider.dart';
import '../../../feedback/providers/feedback_provider.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final tripProvider = context.read<TripProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final trip = await tripProvider.getTripById(widget.tripId);
    await bookingProvider.loadBookings();
    if (!mounted || trip == null) return;
    await context.read<FeedbackProvider>().loadFeedbackForUser(trip.driverId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.watch<TripProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final feedbackProvider = context.watch<FeedbackProvider>();
    final trip = tripProvider.selectedTrip;
    final loading = tripProvider.loading && trip == null;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tripProvider.error ?? 'Trip not found'),
                const SizedBox(height: 12),
                AppButton(text: 'Try again', onPressed: _loadData),
              ],
            ),
          ),
        ),
      );
    }

    final timeFmt = DateFormat('EEE, MMM d • HH:mm');
    final seatsLeft = trip.seatsLeft;
    final model = trip.vehicleModel ?? 'Vehicle';
    final plate = trip.vehiclePlate ?? 'Unknown plate';
    final rating = trip.driverRating ?? 0;
    final reviewsCount = feedbackProvider.ratings.length;
    final imageUrl = trip.driverImage;
    final hasPhoto = imageUrl != null &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
    final hasActiveBooking = bookingProvider.bookings.any(
      (b) =>
          b.tripId == widget.tripId &&
          b.status != BookingStatus.canceled &&
          b.status != BookingStatus.completed,
    ) ||
        (bookingProvider.activeBooking?.tripId == widget.tripId &&
            bookingProvider.activeBooking!.status != BookingStatus.canceled &&
            bookingProvider.activeBooking!.status != BookingStatus.completed);
    final canBook = !hasActiveBooking && seatsLeft > 0;
    final canSubscribe = trip.seriesId != null && !hasActiveBooking;
    final scheme = Theme.of(context).colorScheme;
    final tripsCount = tripProvider.tripBookings.length;
    final bookedCount = tripProvider.tripBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 126),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.95),
                  AppColors.primaryDark.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.origin} → ${trip.destination}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricBadge(Icons.schedule, timeFmt.format(trip.departureTime)),
                    _metricBadge(Icons.route_outlined, '${trip.distanceKm.toStringAsFixed(1)} ${l10n.km}'),
                    _metricBadge(Icons.payments_outlined,
                        '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}'),
                    _metricBadge(Icons.event_seat, '$seatsLeft ${l10n.seats} left'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statCard('Bookings', '$tripsCount', Icons.people_alt_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('Confirmed', '$bookedCount', Icons.verified_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('Seats left', '$seatsLeft', Icons.event_seat_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Driver details'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: hasPhoto ? NetworkImage(imageUrl) : null,
                      child: hasPhoto
                          ? null
                          : const Icon(
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
                            trip.driverName ?? 'Driver',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          if (trip.driverEmail != null &&
                              trip.driverEmail!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              trip.driverEmail!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          if (trip.driverPhone != null &&
                              trip.driverPhone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              trip.driverPhone!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AppRatingWidget(rating: rating, size: 16),
                    const SizedBox(width: 8),
                    Text(rating > 0 ? rating.toStringAsFixed(1) : 'No rating'),
                    const SizedBox(width: 8),
                    Text('• $reviewsCount reviews'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Trip timeline'),
                const SizedBox(height: 10),
                _timelineRow(context, 'Departure', timeFmt.format(trip.departureTime)),
                _timelineRow(context, 'From', trip.origin),
                _timelineRow(context, 'To', trip.destination, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Car information'),
                const SizedBox(height: 10),
                _infoRow(context, 'Model', model),
                _infoRow(context, 'Plate', plate),
                _infoRow(context, 'Capacity',
                    '${trip.vehicleSeats ?? trip.availableSeats} seats'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Subscription'),
                const SizedBox(height: 10),
                Text(
                  trip.seriesId != null
                      ? 'This trip supports subscription bookings.'
                      : 'This trip is available as one-time booking only.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.paddingOf(context).bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canBook)
              AppButton(
                text: l10n.requestBooking,
                onPressed: () => context.push('/booking-confirm/${widget.tripId}'),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasActiveBooking
                      ? 'You already booked this trip.'
                      : 'No seats left for this trip.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            if (canSubscribe) ...[
              const SizedBox(height: 8),
              AppButton(
                text: l10n.subscribe,
                isOutlined: true,
                onPressed: () => context.push('/subscription/${widget.tripId}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _metricBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 1),
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

}
