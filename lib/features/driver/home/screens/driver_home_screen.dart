import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/providers/auth_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  List<Map<String, dynamic>> _mockTrips = [];

  @override
  void initState() {
    super.initState();
    _loadMockTrips();
  }

  void _loadMockTrips() {
    _mockTrips = [
      {
        'id': 't1',
        'origin': 'Bole',
        'destination': 'Megenagna',
        'time': '08:00 AM',
        'seatsAvailable': 3,
        'price': 45,
        'status': TripStatus.scheduled,
      },
      {
        'id': 't2',
        'origin': 'Kazanchis',
        'destination': 'CMC',
        'time': '05:30 PM',
        'seatsAvailable': 2,
        'price': 35,
        'status': TripStatus.scheduled,
      },
      {
        'id': 't3',
        'origin': 'Piassa',
        'destination': 'Bole',
        'time': '07:45 AM',
        'seatsAvailable': 4,
        'price': 50,
        'status': TripStatus.inProgress,
      },
    ];
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _loadMockTrips());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final driverName = authProvider.user?.name ?? 'Driver';

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.home}, $driverName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    _buildStatsRow(l10n),
                    const SizedBox(height: 28),
                    Text(
                      l10n.scheduledTrips,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = _mockTrips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TripCard(
                        trip: trip,
                        l10n: l10n,
                        onTap: () => context.push('/trip-detail/${trip['id']}'),
                      ),
                    );
                  },
                  childCount: _mockTrips.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'recurring',
            onPressed: () => context.push('/create-series'),
            child: const Icon(Icons.repeat),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'newTrip',
            onPressed: () => context.push('/create-trip'),
            icon: const Icon(Icons.add),
            label: const Text('New Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '24', label: l10n.totalTrips, icon: Icons.route)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '1', label: l10n.activeTrip, icon: Icons.play_circle_outline)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '1,250', label: l10n.earnings, icon: Icons.account_balance_wallet_outlined)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] as TripStatus;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip['origin']} → ${trip['destination']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                trip['time'] as String,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.event_seat_outlined, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                '${trip['seatsAvailable']} ${l10n.seats}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${trip['price']} ${l10n.etb}${l10n.perSeat}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TripStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TripStatus.scheduled:
        color = AppColors.info;
        break;
      case TripStatus.inProgress:
        color = AppColors.success;
        break;
      case TripStatus.completed:
        color = AppColors.textSecondaryLight;
        break;
      case TripStatus.canceled:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _statusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return 'Scheduled';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.canceled:
        return 'Canceled';
    }
  }
}
