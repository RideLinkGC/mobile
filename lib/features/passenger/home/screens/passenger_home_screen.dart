import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../auth/providers/auth_provider.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  List<Map<String, dynamic>> _recommendedTrips = [];
  List<Map<String, dynamic>> _recentTrips = [];
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _loadMockData() {
    _recommendedTrips = [
      {
        'id': 't1',
        'driverName': 'Abebe Kebede',
        'origin': 'Bole',
        'destination': 'Megenagna',
        'rating': 4.8,
        'price': 45,
        'seatsAvailable': 3,
      },
      {
        'id': 't2',
        'driverName': 'Tigist Hailu',
        'origin': 'Kazanchis',
        'destination': 'CMC',
        'rating': 4.5,
        'price': 35,
        'seatsAvailable': 2,
      },
      {
        'id': 't3',
        'driverName': 'Dawit Alemu',
        'origin': 'Piassa',
        'destination': 'Bole',
        'rating': 4.9,
        'price': 50,
        'seatsAvailable': 4,
      },
    ];
    _recentTrips = [
      {
        'id': 't4',
        'driverName': 'Sara Mohammed',
        'origin': 'CMC',
        'destination': 'Bole',
        'rating': 4.7,
        'price': 40,
        'seatsAvailable': 2,
      },
      {
        'id': 't5',
        'driverName': 'Yonas Tesfaye',
        'origin': 'Megenagna',
        'destination': 'Kazanchis',
        'rating': 4.6,
        'price': 30,
        'seatsAvailable': 1,
      },
    ];
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _loadMockData());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(l10n.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: GebetaMapWidget(
                  initialCenter: _userLocation,
                  initialZoom: 14,
                  showUserLocation: true,
                  interactive: false,
                  markers: _userLocation != null
                      ? [MapMarker(position: _userLocation!)]
                      : [],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $userName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.lightDivider),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.searchRide,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppColors.textHintLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recommended Trips',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => context.push('/search'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _recommendedTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _recommendedTrips[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 280,
                        child: _TripCard(
                          trip: trip,
                          l10n: l10n,
                          onTap: () =>
                              context.push('/driver-detail/${trip['id']}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Recent Trips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = _recentTrips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TripCard(
                        trip: trip,
                        l10n: l10n,
                        onTap: () =>
                            context.push('/driver-detail/${trip['id']}'),
                      ),
                    );
                  },
                  childCount: _recentTrips.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/search'),
        child: const Icon(Icons.search),
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
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trip['driverName'] as String,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip['origin']} → ${trip['destination']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppRatingWidget(
                rating: (trip['rating'] as num).toDouble(),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${trip['price']} ${l10n.etb}${l10n.perSeat}',
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
                  '${trip['seatsAvailable']} ${l10n.seats}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
