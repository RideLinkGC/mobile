import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/place_search_storage.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/location_search_field.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../providers/search_provider.dart';
import '../widgets/filter_rides_sheet.dart';
import '../widgets/ride_search_cards.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  GeocodingResult? _originResult;
  GeocodingResult? _destinationResult;
  List<RouteSearchHistoryEntry> _routeHistory = [];
  LatLng? _userLocation;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _availableSectionKey = GlobalKey();

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Trigger pagination slightly before reaching the very bottom.
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      context.read<SearchProvider>().loadNextBrowsePage();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRouteHistory();
    });
    _loadUserLocation();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SearchProvider>().setBrowseBackendFilters(
            status: 'scheduled',
            page: 1,
            limit: 10,
          );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _loadRouteHistory() async {
    final storage = context.read<PlaceSearchStorage>();
    final list = await storage.getRouteHistory();
    if (mounted) setState(() => _routeHistory = list);
  }

  Future<void> _onSearch() async {
    if (_originResult == null || _destinationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both origin and destination')),
      );
      return;
    }
    final storage = context.read<PlaceSearchStorage>();
    await storage.addRouteSearch(_originResult!, _destinationResult!);
    await _loadRouteHistory();

    if (!mounted) return;
    context.push('/search-results', extra: {
      'origin': _originResult!.name,
      'destination': _destinationResult!.name,
      'originLat': _originResult!.lat,
      'originLng': _originResult!.lng,
      'destLat': _destinationResult!.lat,
      'destLng': _destinationResult!.lng,
    });
  }

  String get _whereToLabel {
    if (_originResult != null && _destinationResult != null) {
      return '${_originResult!.name} → ${_destinationResult!.name}';
    }
    return 'Where to?';
  }

  Future<void> _openPlanRideSheet(AppLocalizations l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _PlanRideSheet(
          l10n: l10n,
          initialOrigin: _originResult,
          initialDestination: _destinationResult,
          routeHistory: _routeHistory,
          onClearRecents: () async {
            final storage = context.read<PlaceSearchStorage>();
            await storage.clearRouteHistory();
            if (mounted) setState(() => _routeHistory = []);
          },
          onSearchPressed: (o, d) {
            setState(() {
              _originResult = o;
              _destinationResult = d;
            });
            Navigator.of(ctx).pop();
            context.read<SearchProvider>().setBrowseBackendFilters(
                  origin: _originResult?.name,
                  destination: _destinationResult?.name,
                  status: 'scheduled',
                  page: 1,
                  limit: 10,
                );
            _onSearch();
          },
          onApplyOnly: (o, d) {
            setState(() {
              _originResult = o;
              _destinationResult = d;
            });
            context.read<SearchProvider>().setBrowseBackendFilters(
                  origin: _originResult?.name,
                  destination: _destinationResult?.name,
                  status: 'scheduled',
                  page: 1,
                  limit: 10,
                );
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _openFilterRidesSheet() {
    FilterRidesSheet.show(context);
  }

  void _scrollToAvailableList() {
    final ctx = _availableSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  static String _browseSortSummary(BrowseSortMode mode, AppLocalizations l10n) {
    switch (mode) {
      case BrowseSortMode.name:
        return 'Name';
      case BrowseSortMode.price:
        return 'Price';
      case BrowseSortMode.rating:
        return l10n.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar:AppBar(
        title: Text("Find Rides"),centerTitle: true,
        leading: const ShellMenuButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPlanRideSheet(l10n),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, _) {
          final nearbyCount = searchProvider.browseDriverTrips.length;
          final sorted = searchProvider.browseDriverTripsSorted;
          final recommended = searchProvider.recommendedBrowseTrips;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => searchProvider.loadBrowseDrivers(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Material(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(28),
                            child: InkWell(
                              onTap: () => _openPlanRideSheet(l10n),
                              borderRadius: BorderRadius.circular(28),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                child: Row(
                                  children: [
                                    Icon(Icons.search_rounded,
                                        color: scheme.primary, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _whereToLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: _originResult != null &&
                                                      _destinationResult !=
                                                          null
                                                  ? scheme.onSurface
                                                  : scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: scheme.surfaceContainerHigh,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _openFilterRidesSheet,
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.tune_rounded,
                                  color: scheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 148,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GebetaMapWidget(
                              initialCenter: _userLocation,
                              initialZoom: 13,
                              showUserLocation: true,
                              interactive: false,
                              markers: _userLocation != null
                                  ? [MapMarker(position: _userLocation!)]
                                  : [],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    scheme.surface.withValues(alpha: 0.05),
                                    scheme.surface.withValues(alpha: 0.45),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh
                                      .withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppShadows.softElevated(context),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions_car_rounded,
                                        size: 18, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$nearbyCount drivers nearby',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (searchProvider.browseLoading &&
                    recommended.isEmpty &&
                    sorted.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recommended drivers',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: _scrollToAvailableList,
                            child: const Text('SEE ALL'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recommended.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.noDriversFound,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 218,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: recommended.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final trip = recommended[index];
                            return RecommendedDriverCard(
                              trip: trip,
                              l10n: l10n,
                              showBestMatch: index == 0,
                              onTap: () => context
                                  .push('/passenger-trip-detail/${trip.id}'),
                            );
                          },
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _availableSectionKey,
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.availableDrivers,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openFilterRidesSheet,
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: Text(
                              'Filters · ${_browseSortSummary(searchProvider.browseSortMode, l10n)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (searchProvider.browseError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          searchProvider.browseError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.warning,
                              ),
                        ),
                      ),
                    ),
                  if (sorted.isEmpty && !searchProvider.browseLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.directions_car_outlined,
                                  size: 48, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noDriversFound,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < sorted.length) {
                              final trip = sorted[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AvailableDriverRideCard(
                                  trip: trip,
                                  l10n: l10n,
                                  onTap: () => context.push(
                                      '/passenger-trip-detail/${trip.id}'),
                                ),
                              );
                            }

                            // Bottom indicator row (pagination).
                            if (searchProvider.browseLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (!searchProvider.browseHasMore &&
                                sorted.isNotEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Center(
                                  child: Text(
                                    'No more rides',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              );
                            }

                            // Nothing to show.
                            return const SizedBox.shrink();
                          },
                          childCount: sorted.length + 1,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanRideSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final GeocodingResult? initialOrigin;
  final GeocodingResult? initialDestination;
  final List<RouteSearchHistoryEntry> routeHistory;
  final VoidCallback onClearRecents;
  final void Function(GeocodingResult? o, GeocodingResult? d) onSearchPressed;
  final void Function(GeocodingResult? o, GeocodingResult? d) onApplyOnly;

  const _PlanRideSheet({
    required this.l10n,
    required this.initialOrigin,
    required this.initialDestination,
    required this.routeHistory,
    required this.onClearRecents,
    required this.onSearchPressed,
    required this.onApplyOnly,
  });

  @override
  State<_PlanRideSheet> createState() => _PlanRideSheetState();
}

class _PlanRideSheetState extends State<_PlanRideSheet> {
  GeocodingResult? _origin;
  GeocodingResult? _destination;

  @override
  void initState() {
    super.initState();
    _origin = widget.initialOrigin;
    _destination = widget.initialDestination;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Plan a ride',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
           
            LocationSearchField(
              hintText: widget.l10n.origin,
              prefixIcon: Icons.trip_origin,
              onPlaceSelected: (r) => setState(() => _origin = r),
            ),
            const SizedBox(height: 16),
            
            LocationSearchField(
              hintText: widget.l10n.destination,
              prefixIcon: Icons.location_on,
              onPlaceSelected: (r) => setState(() => _destination = r),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: widget.l10n.search,
              onPressed: () {
                if (_origin == null || _destination == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please select both origin and destination')),
                  );
                  return;
                }
                widget.onSearchPressed(_origin, _destination);
              },
            ),
           
            if (widget.routeHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent searches',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton(
                    onPressed: widget.onClearRecents,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...widget.routeHistory.map(
                (entry) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push('/search-results', extra: {
                      'origin': entry.origin.name,
                      'destination': entry.destination.name,
                      'originLat': entry.origin.lat,
                      'originLng': entry.origin.lng,
                      'destLat': entry.destination.lat,
                      'destLng': entry.destination.lng,
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
