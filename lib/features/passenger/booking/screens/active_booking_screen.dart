import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../emergency/widgets/emergency_alert_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/constants/enums.dart';
import '../providers/booking_provider.dart';

class ActiveBookingScreen extends StatefulWidget {
  final String tripId;

  const ActiveBookingScreen({super.key, required this.tripId});

  @override
  State<ActiveBookingScreen> createState() => _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends State<ActiveBookingScreen> {
  BookingModel? _booking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooking();
    });
  }

  Future<void> _loadBooking() async {
    final provider = context.read<BookingProvider>();
    if (provider.bookings.isEmpty) {
      await provider.loadBookings();
    }
    if (!mounted) return;
    final booking = provider.bookings
        .where((b) => b.tripId == widget.tripId)
        .where((b) =>
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.confirmed)
        .firstOrNull;
    setState(() => _booking = booking);
  }

  void _onCancelBooking() {
    final l10n = AppLocalizations.of(context)!;
    final booking = _booking;
    if (booking == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelBooking),
        content: const Text(
          'Are you sure you want to cancel this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success =
                  await context.read<BookingProvider>().cancelBooking(booking.id);
              if (mounted) {
                if (success) {
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<BookingProvider>().error ??
                            'Failed to cancel booking',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingProvider = context.watch<BookingProvider>();
    final booking = _booking;
    final loading = bookingProvider.loading && booking == null;

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myTrips)),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myTrips)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Booking not found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final departureFormatted = booking.tripDepartureTime != null
        ? DateFormat.jm().format(booking.tripDepartureTime!)
        : '—';
    final origin = booking.tripOrigin ?? '—';
    final destination = booking.tripDestination ?? '—';
    final pickupPoint = booking.pickUpPoint ?? origin;
    final conversationId = 'trip_${booking.tripId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myTrips),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$origin → $destination',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _StatusChip(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.departureTime}: $departureFormatted',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pickup: $pickupPoint',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${booking.totalPrice.toStringAsFixed(0)} ${l10n.etb}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
                    'Driver Contact',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking.driverName ?? 'Driver',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Contact via in-app chat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.liveTracking,
              icon: Icons.location_on,
              onPressed: () => context.push('/tracking/${widget.tripId}'),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: l10n.chat,
              icon: Icons.chat_bubble_outline,
              onPressed: () => context.push('/chat/$conversationId'),
              isOutlined: true,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: l10n.sos,
              icon: Icons.emergency,
              onPressed: () =>
                  showEmergencyAlertFlow(context, widget.tripId),
              backgroundColor: AppColors.sosRed,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: l10n.cancelBooking,
              onPressed: _onCancelBooking,
              isOutlined: true,
              foregroundColor: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      BookingStatus.pending => (l10n.bookingPending, AppColors.warning),
      BookingStatus.confirmed => (l10n.bookingConfirmed, AppColors.success),
      BookingStatus.canceled => ('Canceled', AppColors.error),
      BookingStatus.completed => ('Completed', AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
