import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../driver/trip/models/trip_model.dart';
import '../providers/search_provider.dart';

class SearchResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const SearchResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      context.read<SearchProvider>().searchTrips(
            origin: widget.origin,
            destination: widget.destination,
            originLat: extra?['originLat'] as double?,
            originLng: extra?['originLng'] as double?,
            destLat: extra?['destLat'] as double?,
            destLng: extra?['destLng'] as double?,
          );
    });
  }

  void _showFilterSheet() {
    final provider = context.read<SearchProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.origin} → ${widget.destination}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: SortMode.values.map((mode) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_sortLabel(mode, l10n)),
                          avatar: provider.sortMode == mode
                              ? null
                              : Icon(_sortIcon(mode), size: 16),
                          selected: provider.sortMode == mode,
                          onSelected: (_) => provider.setSortMode(mode),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    provider.error!,
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  '${provider.searchResults.length} trips found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ),
              Expanded(
                child: provider.searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.textHintLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noDriversFound,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (provider.maxPrice != null ||
                                provider.minSeats != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: provider.clearFilters,
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: provider.searchResults.length,
                        itemBuilder: (context, index) {
                          final trip = provider.searchResults[index];
                          final isTop = index == 0 &&
                              provider.sortMode == SortMode.recommended;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TripCard(
                              trip: trip,
                              l10n: l10n,
                              isRecommended: isTop,
                              onTap: () =>
                                  context.push('/driver-detail/${trip.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _sortLabel(SortMode mode, AppLocalizations l10n) {
    switch (mode) {
      case SortMode.recommended:
        return 'Recommended';
      case SortMode.price:
        return 'Price';
      case SortMode.rating:
        return l10n.rating;
      case SortMode.time:
        return 'Departure';
      case SortMode.seats:
        return l10n.seats;
    }
  }

  IconData _sortIcon(SortMode mode) {
    switch (mode) {
      case SortMode.recommended:
        return Icons.auto_awesome;
      case SortMode.price:
        return Icons.payments_outlined;
      case SortMode.rating:
        return Icons.star_outline;
      case SortMode.time:
        return Icons.schedule;
      case SortMode.seats:
        return Icons.event_seat_outlined;
    }
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final AppLocalizations l10n;
  final bool isRecommended;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.l10n,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.jm();

    return Stack(
      children: [
        AppCard(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driverName ?? 'Driver',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    if (trip.driverRating != null)
                      AppRatingWidget(
                        rating: trip.driverRating!,
                        size: 16,
                      ),
                    const SizedBox(height: 8),
                    if (trip.vehicleModel != null || trip.vehiclePlate != null)
                      Text(
                        [trip.vehicleModel, trip.vehiclePlate]
                            .where((e) => e != null)
                            .join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeFmt.format(trip.departureTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '${trip.seatsLeft} ${l10n.seats}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: 0,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Best Match',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final SearchProvider provider;

  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double? _maxPrice;
  late int? _minSeats;
  late TimeOfDay? _preferredTime;

  @override
  void initState() {
    super.initState();
    _maxPrice = widget.provider.maxPrice;
    _minSeats = widget.provider.minSeats;
    _preferredTime = widget.provider.preferredTime;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _maxPrice = null;
                    _minSeats = null;
                    _preferredTime = null;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Max price per seat (ETB)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: _maxPrice ?? 200,
            min: 10,
            max: 200,
            divisions: 19,
            label: _maxPrice != null
                ? '${_maxPrice!.toStringAsFixed(0)} ETB'
                : 'Any',
            onChanged: (v) => setState(() => _maxPrice = v),
          ),
          const SizedBox(height: 12),
          Text(
            'Minimum seats available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final seats = i + 1;
              final selected = _minSeats == seats;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$seats+'),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _minSeats = selected ? null : seats),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Preferred departure time',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _preferredTime ?? TimeOfDay.now(),
              );
              if (picked != null) setState(() => _preferredTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppShadows.softCard(context),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _preferredTime != null
                        ? _preferredTime!.format(context)
                        : 'Any time',
                  ),
                  const Spacer(),
                  if (_preferredTime != null)
                    GestureDetector(
                      onTap: () => setState(() => _preferredTime = null),
                      child: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              widget.provider.setMaxPrice(_maxPrice);
              widget.provider.setMinSeats(_minSeats);
              widget.provider.setPreferredTime(_preferredTime);
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
