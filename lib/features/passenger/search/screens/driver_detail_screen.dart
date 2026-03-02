import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/rating_widget.dart';

class DriverDetailScreen extends StatefulWidget {
  final String tripId;

  const DriverDetailScreen({super.key, required this.tripId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  RouteResult? _route;
  bool _loadingRoute = true;

  final _originLatLng = const LatLng(9.0192, 38.7525);
  final _destLatLng = const LatLng(9.0300, 38.7800);

  final driver = {
    'name': 'Abebe Kebede',
    'rating': 4.8,
    'vehicleModel': 'Toyota Corolla',
    'vehiclePlate': 'AA-12345',
    'vehicleSeats': 4,
  };

  final trip = {
    'origin': 'Bole',
    'destination': 'Megenagna',
    'departureTime': '08:00 AM',
    'price': 45,
    'seatsAvailable': 3,
    'isSubscribable': true,
  };

  final reviews = [
    {'rating': 5.0, 'comment': 'Great driver, very punctual!', 'date': '2 days ago'},
    {'rating': 4.5, 'comment': 'Smooth ride, would recommend.', 'date': '1 week ago'},
    {'rating': 5.0, 'comment': 'Friendly and professional.', 'date': '2 weeks ago'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final mapsService = context.read<GebetaMapsService>();
    final route = await mapsService.getRoute(
      originLat: _originLatLng.latitude,
      originLng: _originLatLng.longitude,
      destLat: _destLatLng.latitude,
      destLng: _destLatLng.longitude,
    );
    if (mounted) {
      setState(() {
        _route = route;
        _loadingRoute = false;
      });
    }
  }

  List<LatLng> get _routePolyline {
    if (_route == null) return [];
    return _route!.polylinePoints
        .map((p) => LatLng(p[0], p[1]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip['origin']} → ${trip['destination']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: _loadingRoute
                    ? const Center(child: CircularProgressIndicator())
                    : GebetaMapWidget(
                        initialCenter: _originLatLng,
                        initialZoom: 13,
                        interactive: false,
                        markers: [
                          MapMarker(position: _originLatLng),
                          MapMarker(position: _destLatLng),
                        ],
                        polylines: _routePolyline.isNotEmpty
                            ? [MapPolyline(points: _routePolyline, color: '#188AEC', width: 4)]
                            : [],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_route != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _InfoChip(
                      icon: Icons.straighten,
                      label: '${_route!.distanceKm.toStringAsFixed(1)} km',
                    ),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '${_route!.durationMinutes.toStringAsFixed(0)} min',
                    ),
                  ],
                ),
              ),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        AppRatingWidget(
                          rating: (driver['rating'] as num).toDouble(),
                          size: 18,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${driver['vehicleModel']} (${driver['vehiclePlate']})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${driver['vehicleSeats']} ${l10n.seats}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip Details', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
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
                      Icon(Icons.access_time, size: 18, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.departureTime}: ${trip['departureTime']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 18, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.pricePerSeat}: ${trip['price']} ${l10n.etb}${l10n.perSeat}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event_seat_outlined, size: 18, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        '${trip['seatsAvailable']} ${l10n.seats}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
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
                            rating: (r['rating'] as num).toDouble(),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(r['date'] as String, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r['comment'] as String, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.requestBooking,
              onPressed: () => context.push('/booking-confirm/${widget.tripId}'),
            ),
            if (trip['isSubscribable'] as bool) ...[
              const SizedBox(height: 12),
              AppButton(
                text: l10n.subscribe,
                onPressed: () => context.push('/subscription/${widget.tripId}'),
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
