import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../passenger/booking/models/booking_model.dart';
import '../../trip/models/trip_model.dart';

class DriverCurrentTripCard extends StatelessWidget {
  final TripModel trip;
  final List<BookingModel> bookings;
  final int? etaMinutes;
  final double? distanceKm;
  final VoidCallback onOpen;
  final VoidCallback? onStart;
  final VoidCallback? onOpenTracking;
  final VoidCallback? onRequests;

  const DriverCurrentTripCard({
    super.key,
    required this.trip,
    required this.bookings,
    required this.onOpen,
    this.etaMinutes,
    this.distanceKm,
    this.onStart,
    this.onOpenTracking,
    this.onRequests,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeFmt = DateFormat.jm();

    final pending = bookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmed = bookings.where((b) => b.status == BookingStatus.confirmed).length;

    final eta = (etaMinutes != null && etaMinutes! > 0) ? '${etaMinutes!} min' : '-- min';
    final dist = (distanceKm != null && distanceKm! > 0) ? '${distanceKm!.toStringAsFixed(1)} ${l10n.km}' : '-- ${l10n.km}';

    final statusLabel = switch (trip.status) {
      TripStatus.inProgress => l10n.activeTrip,
      TripStatus.scheduled => l10n.scheduledTrips,
      TripStatus.completed => 'Completed',
      TripStatus.canceled => 'Canceled',
    };

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.origin} → ${trip.destination}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: timeFmt.format(trip.departureTime), icon: Icons.schedule),
              _Chip(label: eta, icon: Icons.timelapse_rounded),
              _Chip(label: dist, icon: Icons.route_rounded),
              _Chip(
                label: '${trip.seatsLeft}/${trip.availableSeats} ${l10n.seats}',
                icon: Icons.event_seat_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CountPill(
                label: 'Confirmed',
                value: confirmed.toString(),
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _CountPill(
                label: 'Pending',
                value: pending.toString(),
                color: AppColors.warning,
              ),
              const Spacer(),
              Text(
                '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trip.status == TripStatus.scheduled && onStart != null)
            AppButton(
              text: 'Start Trip',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            )
          else if (trip.status == TripStatus.inProgress && onOpenTracking != null)
            AppButton(
              text: 'Open Live Tracking',
              icon: Icons.my_location_rounded,
              onPressed: onOpenTracking,
            )
          else
            AppButton(
              text: l10n.tripSchedule,
              icon: Icons.info_outline,
              onPressed: onOpen,
              isOutlined: true,
            ),
          if (onRequests != null) ...[
            const SizedBox(height: 10),
            AppButton(
              text: l10n.bookingRequests,
              icon: Icons.person_add_alt_1_outlined,
              onPressed: onRequests,
              isOutlined: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

