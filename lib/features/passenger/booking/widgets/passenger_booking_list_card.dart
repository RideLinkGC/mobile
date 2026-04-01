import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../models/passenger_booking_list_item.dart';

class PassengerBookingListCard extends StatelessWidget {
  final PassengerBookingListItem item;
  final AppLocalizations l10n;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  const PassengerBookingListCard({
    super.key,
    required this.item,
    required this.l10n,
    this.onTap,
    this.onAccept,
    this.onCancel,
  });

  String _kindChipLabel() {
    switch (item.kind) {
      case PassengerBookingListKind.awaitingPassengerConfirmation:
        return l10n.bookingKindAwaitingYou;
      case PassengerBookingListKind.pendingDriverConfirmation:
        return l10n.bookingKindPendingDriver;
      case PassengerBookingListKind.active:
        return l10n.bookingKindActive;
    }
  }

  Color _kindChipColor() {
    switch (item.kind) {
      case PassengerBookingListKind.awaitingPassengerConfirmation:
        return const Color(0xFF1565C0);
      case PassengerBookingListKind.pendingDriverConfirmation:
        return const Color(0xFFE65100);
      case PassengerBookingListKind.active:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatted =
        DateFormat('h:mm a · EEE, MMM d').format(item.departureTime);
    final showActions =
        onAccept != null && onCancel != null && item.kind == PassengerBookingListKind.awaitingPassengerConfirmation;

    return AppCard(
      color: Theme.of(context).colorScheme.surface.withAlpha(125),
      onTap: showActions ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.driverName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kindChipColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _kindChipLabel(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _kindChipColor(),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (item.isRecurrent && item.recurrenceLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.recurrentTrip}: ${item.recurrenceLabel}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.origin} → ${item.destination}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  timeFormatted,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${item.totalPrice.toStringAsFixed(0)} ${l10n.etb}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.seatsBooked} ${l10n.seats}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      // backgroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onCancel,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: Text(l10n.accept),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
