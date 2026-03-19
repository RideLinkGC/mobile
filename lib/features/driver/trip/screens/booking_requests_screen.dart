import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../passenger/booking/models/booking_model.dart';
import '../providers/trip_provider.dart';

class BookingRequestsScreen extends StatefulWidget {
  final String tripId;

  const BookingRequestsScreen({super.key, required this.tripId});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadTripBookings(widget.tripId);
    });
  }

  Future<void> _accept(BookingModel booking) async {
    final provider = context.read<TripProvider>();
    final success = await provider.acceptBooking(booking.id);
    if (!mounted) return;

    if (success) {
      await provider.loadTripBookings(widget.tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking accepted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to accept booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _decline(BookingModel booking) async {
    final provider = context.read<TripProvider>();
    final success = await provider.declineBooking(booking.id);
    if (!mounted) return;

    if (success) {
      await provider.loadTripBookings(widget.tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking declined'),
          backgroundColor: AppColors.textSecondaryLight,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to decline booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.watch<TripProvider>();
    final allBookings = tripProvider.tripBookings;
    final pendingRequests =
        allBookings.where((b) => b.status == BookingStatus.pending).toList();
    final isLoading = tripProvider.loading && allBookings.isEmpty;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookingRequests)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (pendingRequests.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookingRequests)),
        body: _buildEmptyState(l10n),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingRequests),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          final booking = pendingRequests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BookingRequestCard(
              booking: booking,
              l10n: l10n,
              onAccept: () => _accept(booking),
              onDecline: () => _decline(booking),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.textHintLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No booking requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Requests will appear here when passengers book this trip',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final BookingModel booking;
  final AppLocalizations l10n;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _BookingRequestCard({
    required this.booking,
    required this.l10n,
    required this.onAccept,
    required this.onDecline,
  });

  String _getPassengerLabel() {
    return 'Passenger #${booking.passengerId.length > 8 ? booking.passengerId.substring(0, 8) : booking.passengerId}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                child: Text(
                  (_getPassengerLabel().isNotEmpty ? _getPassengerLabel().substring(0, 1) : 'P').toUpperCase(),
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
                      _getPassengerLabel(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''} · ${booking.totalPrice.toStringAsFixed(0)} ${l10n.etb}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.trip_origin, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.pickUpPoint ?? '—',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.dropOffPoint ?? '—',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.accept,
                  onPressed: onAccept,
                  backgroundColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: l10n.decline,
                  onPressed: onDecline,
                  isOutlined: true,
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
