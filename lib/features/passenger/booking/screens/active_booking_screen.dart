import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

enum BookingStatus { pending, confirmed }

class ActiveBookingScreen extends StatelessWidget {
  final String tripId;

  const ActiveBookingScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final booking = {
      'status': BookingStatus.confirmed,
      'driverName': 'Abebe Kebede',
      'driverPhone': '+251911234567',
      'conversationId': 'conv_$tripId',
      'origin': 'Bole',
      'destination': 'Megenagna',
      'departureTime': '08:00 AM',
      'pickupPoint': 'Bole Road, near Edna Mall',
      'price': 45,
    };

    final status = booking['status'] as BookingStatus;

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
                        '${booking['origin']} → ${booking['destination']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.departureTime}: ${booking['departureTime']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pickup: ${booking['pickupPoint']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${booking['price']} ${l10n.etb}',
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
                    booking['driverName'] as String,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    booking['driverPhone'] as String,
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
              onPressed: () => context.push('/tracking/$tripId'),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: l10n.chat,
              icon: Icons.chat_bubble_outline,
              onPressed: () => context.push('/chat/${booking['conversationId']}'),
              isOutlined: true,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: l10n.sos,
              icon: Icons.emergency,
              onPressed: () => context.push('/sos/$tripId'),
              backgroundColor: AppColors.sosRed,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: l10n.cancelBooking,
              onPressed: () {
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
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.pop();
                        },
                        child: Text(l10n.confirm),
                      ),
                    ],
                  ),
                );
              },
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
