import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../trip/providers/trip_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadDriverTrips();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<TripProvider>().loadDriverTrips();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final driverName = authProvider.user?.name ?? 'Driver';
    final trips = tripProvider.driverTrips;

    final scheduledCount =
        trips.where((t) => t.status == TripStatus.scheduled).length;
    final activeCount =
        trips.where((t) => t.status == TripStatus.inProgress).length;
    final earnings = trips
        .where((t) => t.status == TripStatus.completed)
        .fold<double>(0, (sum, t) => sum + t.pricePerSeat * t.bookedSeats);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
                child: Row(
                  children: [
                    const ShellMenuButton(),
                    Expanded(
                      child: Text(
                        '${l10n.home}, $driverName',
                        style: Theme.of(context).textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                value: scheduledCount.toString(),
                                label: l10n.totalTrips,
                                icon: Icons.route)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _StatCard(
                                value: '$activeCount',
                                label: l10n.activeTrip,
                                icon: Icons.play_circle_outline)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _StatCard(
                                value:
                                    earnings.toStringAsFixed(0),
                                label: l10n.earnings,
                                icon:
                                    Icons.account_balance_wallet_outlined)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.scheduledTrips,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            if (tripProvider.loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (trips.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.route,
                            size: 64, color: AppColors.textHintLight),
                        const SizedBox(height: 16),
                        Text('No trips yet',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trip = trips[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TripCard(
                          trip: trip,
                          l10n: l10n,
                          onTap: () =>
                              context.push('/trip-detail/${trip.id}'),
                        ),
                      );
                    },
                    childCount: trips.length,
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
  final TripModel trip;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.jm();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip.origin} → ${trip.destination}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(status: trip.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                timeFmt.format(trip.departureTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.event_seat_outlined,
                  size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                '${trip.seatsLeft} ${l10n.seats}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
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
    final (color, label) = switch (status) {
      TripStatus.scheduled => (AppColors.info, 'Scheduled'),
      TripStatus.inProgress => (AppColors.success, 'In Progress'),
      TripStatus.completed => (AppColors.textSecondaryLight, 'Completed'),
      TripStatus.canceled => (AppColors.error, 'Canceled'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
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
