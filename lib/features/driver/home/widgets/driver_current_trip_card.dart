import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
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

    return Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surface,
            scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 HEADER (Route + Status)
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Active trips",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color.fromRGBO(12, 207, 237, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // _StatusBadge(status: trip.status),
              ],
            ),

            const SizedBox(height: 14),

            /// 📍 ROUTE VISUAL
            _RouteSection(
              origin: trip.origin,
              destination: trip.destination,
            ),

            const SizedBox(height: 16),

            /// 📊 INFO CHIPS
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ChipModern(
                  label: timeFmt.format(trip.departureTime),
                  icon: Icons.schedule,
                ),
                _ChipModern(
                  label: eta,
                  icon: Icons.timelapse_rounded,
                ),
                _ChipModern(
                  label: dist,
                  icon: Icons.route_rounded,
                ),
                _ChipModern(
                  label: '${trip.seatsLeft}/${trip.availableSeats}',
                  icon: Icons.event_seat_outlined,
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 📈 BOOKINGS + PRICE
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
                  '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// 🚀 ACTION BUTTON
            _buildActionButton(context),

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
      ),
    ),
  ),
); 
    }

    Widget _buildActionButton(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  if (trip.status == TripStatus.scheduled && onStart != null) {
    return AppButton(
      text: 'Start Trip',
      icon: Icons.play_arrow_rounded,
      onPressed: onStart,
    );
  } else if (trip.status == TripStatus.inProgress && onOpenTracking != null) {
    return AppButton(
      text: 'Live Tracking',
      icon: Icons.my_location_rounded,
      onPressed: onOpenTracking,
    );
  } else {
    return AppButton(
      text: l10n.tripSchedule,
      icon: Icons.info_outline,
      onPressed: onOpen,
      isOutlined: true,
    );
  }
}
}



class _RouteSection extends StatelessWidget {
  final String origin;
  final String destination;

  const _RouteSection({
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(Icons.circle, size: 10, color: Colors.green),
            Container(width: 2, height: 30, color: Colors.grey.shade400),
            Icon(Icons.location_on, size: 16, color: Colors.red),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}



class _ChipModern extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ChipModern({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label),
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



