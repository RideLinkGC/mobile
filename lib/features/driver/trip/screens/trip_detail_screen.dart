import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class TripDetailScreen extends StatelessWidget {
  final String? tripId;

  const TripDetailScreen({super.key, this.tripId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = _getMockTrip(tripId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripSchedule),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusChip(status: trip['status'] as TripStatus),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: l10n.origin,
                    value: trip['origin'] as String,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: l10n.destination,
                    value: trip['destination'] as String,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: l10n.departureTime,
                    value: trip['time'] as String,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.event_seat_outlined,
                    label: l10n.seats,
                    value: '${trip['seatsAvailable']}',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: l10n.pricePerSeat,
                    value: '${trip['price']} ${l10n.etb}${l10n.perSeat}',
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
            ...(_getMockPassengers()).map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                        child: Text(
                          (p['name'] as String).substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p['name'] as String,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (trip['status'] == TripStatus.scheduled) ...[
              AppButton(
                text: 'Start Trip',
                icon: Icons.play_arrow,
                onPressed: () => context.push('/tracking/${trip['id']}'),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              text: l10n.bookingRequests,
              icon: Icons.person_add_outlined,
              isOutlined: true,
              onPressed: () => context.push('/booking-requests/${trip['id']}'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getMockTrip(String? id) {
    return {
      'id': id ?? 't1',
      'origin': 'Bole',
      'destination': 'Megenagna',
      'time': '08:00 AM',
      'seatsAvailable': 3,
      'price': 45,
      'status': TripStatus.scheduled,
    };
  }

  List<Map<String, dynamic>> _getMockPassengers() {
    return [
      {'name': 'Abebe Kebede'},
      {'name': 'Sara Mohammed'},
    ];
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
