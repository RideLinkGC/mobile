import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../driver/trip/providers/trip_provider.dart';
import '../../../feedback/providers/feedback_provider.dart';

class DriverDetailScreen extends StatefulWidget {
  final String tripId;

  const DriverDetailScreen({super.key, required this.tripId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final trip = await context.read<TripProvider>().getTripById(widget.tripId);
    if (mounted && trip != null) {
      await context.read<FeedbackProvider>().loadFeedbackForUser(trip.driverId);
    }
  }

  static (String title, String? subtitle) _splitPlace(String raw) {
    final comma = raw.indexOf(',');
    if (comma > 0) {
      return (raw.substring(0, comma).trim(), raw.substring(comma + 1).trim());
    }
  
    final arrow = raw.indexOf('→');
    if (arrow > 0) {
      return (raw.substring(0, arrow).trim(), raw.substring(arrow + 1).trim());
    }
    return (raw, null);
  }

  static String _pickupCountdown(DateTime departure) {
    final m = departure.difference(DateTime.now()).inMinutes;
    if (m < 0) return 'Past';
    if (m < 1) return 'NOW';
    if (m < 60) return 'IN $m MIN';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm > 0 ? 'IN ${h}H ${rm}M' : 'IN ${h}H';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tripProvider = context.watch<TripProvider>();
    final feedbackProvider = context.watch<FeedbackProvider>();
    final trip = tripProvider.selectedTrip;
    final reviews = feedbackProvider.ratings;
    final isLoading = tripProvider.loading && trip == null;

    if (isLoading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('Driver Details'),
          centerTitle: true,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (trip == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('Driver Details'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tripProvider.error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Try Again',
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final timeFmt = DateFormat.jm();
    final departureFormatted = timeFmt.format(trip.departureTime);
    final pickupBadge = _pickupCountdown(trip.departureTime);
    final (pickTitle, pickSub) = _splitPlace(trip.origin);
    final (destTitle, destSub) = _splitPlace(trip.destination);
    final rating = trip.driverRating ?? 0;
    final hasPhoto = trip.driverImage != null &&
        (trip.driverImage!.startsWith('http://') ||
            trip.driverImage!.startsWith('https://'));

    const tripsStat = '—';
    const expStat = '—';
    final safetyStat =
        '${rating > 0 ? rating.clamp(1, 5).toStringAsFixed(1) : '5.0'}/5';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: scheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Driver Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DriverProfileCard(
                    trip: trip,
                    hasPhoto: hasPhoto,
                    tripsStat: tripsStat,
                    expStat: expStat,
                    safetyStat: safetyStat,
                  ),
                  const SizedBox(height: 16),
                  _VehicleCard(trip: trip, l10n: l10n),
                  const SizedBox(height: 16),
                  _PlannedRouteCard(
                    pickTitle: pickTitle,
                    pickSubtitle: pickSub ?? 'Pickup area',
                    destTitle: destTitle,
                    destSubtitle: destSub ?? 'Drop-off area',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatAccentCard(
                          label: 'PRICE',
                          value:
                              '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}',
                          footer: 'per seat',
                          valueIsPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatAccentCard(
                          label: 'AVAILABILITY',
                          value: '${trip.seatsLeft} ${l10n.seats}',
                          footer: 'Remaining',
                          valueIsPrimary: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PickupTimeBar(
                    timeLabel: departureFormatted,
                    badge: pickupBadge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (feedbackProvider.loadingFeedback)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (reviews.isEmpty)
                    Text(
                      'No reviews yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    )
                  else
                    ...reviews.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppRatingWidget(
                                    rating: (r.rating ?? 0).toDouble(),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.createdAt != null
                                        ? DateFormat.yMMMd()
                                            .format(r.createdAt!)
                                        : '',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                r.comment ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/booking-confirm/${widget.tripId}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(
                    l10n.requestBooking,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'By tapping request, you agree to our community standards and carpooling policy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                if (trip.seriesId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push('/subscription/${widget.tripId}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.subscribe),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverProfileCard extends StatelessWidget {
  final TripModel trip;
  final bool hasPhoto;
  final String tripsStat;
  final String expStat;
  final String safetyStat;

  const _DriverProfileCard({
    required this.trip,
    required this.hasPhoto,
    required this.tripsStat,
    required this.expStat,
    required this.safetyStat,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onMuted = scheme.onSurfaceVariant;
    final name = trip.driverName ?? 'Driver';
    final rating = trip.driverRating ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  backgroundImage:
                      hasPhoto ? NetworkImage(trip.driverImage!) : null,
                  child: hasPhoto
                      ? null
                      : Icon(Icons.person_rounded,
                          size: 52, color: scheme.primary),
                ),
              ),
              Positioned(
                bottom: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 16, color: scheme.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : '—',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, size: 18, color: onMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Verified Professional Driver',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(value: tripsStat, label: 'TRIPS'),
              ),
              Expanded(
                child: _ProfileStat(value: expStat, label: 'EXP'),
              ),
              Expanded(
                child: _ProfileStat(value: safetyStat, label: 'SAFETY'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '“Punctuality and passenger comfort are top priorities. A smooth, professional ride every time.”',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onMuted,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final TripModel trip;
  final AppLocalizations l10n;

  const _VehicleCard({required this.trip, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final model = trip.vehicleModel ?? 'Vehicle';
    final plate = trip.vehiclePlate;
    final seats = trip.vehicleSeats ?? trip.availableSeats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surfaceContainerHighest,
                    scheme.primary.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                size: 44,
                color: scheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  plate != null && plate.isNotEmpty
                      ? '$plate • Premium Interior'
                      : 'Comfort class • Premium Interior',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeatureChip(label: 'AC', scheme: scheme),
                    _FeatureChip(label: 'WI-FI', scheme: scheme),
                    _FeatureChip(
                      label: '$seats SEATS',
                      scheme: scheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;

  const _FeatureChip({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class _PlannedRouteCard extends StatelessWidget {
  final String pickTitle;
  final String pickSubtitle;
  final String destTitle;
  final String destSubtitle;

  const _PlannedRouteCard({
    required this.pickTitle,
    required this.pickSubtitle,
    required this.destTitle,
    required this.destSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onMuted = scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLANNED ROUTE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onMuted,
                            ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        destTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatAccentCard extends StatelessWidget {
  final String label;
  final String value;
  final String footer;
  final bool valueIsPrimary;

  const _StatAccentCard({
    required this.label,
    required this.value,
    required this.footer,
    required this.valueIsPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onMuted = scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueIsPrimary ? scheme.primary : null,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  footer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupTimeBar extends StatelessWidget {
  final String timeLabel;
  final String badge;

  const _PickupTimeBar({
    required this.timeLabel,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onMuted = scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule_rounded, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Estimated Pickup',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onMuted,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
