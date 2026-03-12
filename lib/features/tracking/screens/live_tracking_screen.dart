import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/gebeta_maps_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gebeta_map_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tracking_provider.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String tripId;

  const LiveTrackingScreen({super.key, required this.tripId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey();

  final _originLatLng = const LatLng(9.0192, 38.7525);
  final _destLatLng = const LatLng(9.0300, 38.7800);

  RouteResult? _route;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    _startTracking();
  }

  void _startTracking() {
    final authProvider = context.read<AuthProvider>();
    final trackingProvider = context.read<TrackingProvider>();

    if (authProvider.isDriver) {
      trackingProvider.startBroadcasting(widget.tripId);
    } else {
      trackingProvider.startListening(widget.tripId);
    }
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
      setState(() => _route = route);
    }
  }

  List<MapMarker> _buildMarkers(LatLng? driverPos) {
    final markers = <MapMarker>[
      MapMarker(position: _originLatLng),
      MapMarker(position: _destLatLng),
    ];
    if (driverPos != null) {
      markers.add(MapMarker(position: driverPos, iconSize: 2.0));
    }
    return markers;
  }

  List<MapPolyline> get _polylines {
    if (_route == null) return [];
    final points =
        _route!.polylinePoints.map((p) => LatLng(p[0], p[1])).toList();
    return [MapPolyline(points: points, color: '#188AEC', width: 5)];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final trackingProvider = context.watch<TrackingProvider>();
    final isDriver = authProvider.isDriver;
    final driverPos = trackingProvider.driverPosition;

    return Scaffold(
      body: Stack(
        children: [
          GebetaMapWidget(
            key: _mapKey,
            initialCenter: driverPos ?? _originLatLng,
            initialZoom: 14,
            markers: _buildMarkers(driverPos),
            polylines: _polylines,
            showUserLocation: true,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  trackingProvider.stopTracking();
                  context.pop();
                },
              ),
            ),
          ),
          if (trackingProvider.error != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 60,
              right: 60,
              child: Material(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.sosRed.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Text(
                    trackingProvider.error!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.person,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Abebe Kebede',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Toyota Corolla • 4.8 ★',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.eta,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondaryLight),
                              ),
                              Text(
                                _route != null
                                    ? '${_route!.durationMinutes.toStringAsFixed(0)} min'
                                    : '-- min',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Distance',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondaryLight),
                              ),
                              Text(
                                _route != null
                                    ? '${_route!.distanceKm.toStringAsFixed(1)} km'
                                    : '-- km',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isDriver)
                        AppButton(
                          text: 'End Trip',
                          onPressed: () async {
                            await trackingProvider.endTrip();
                            if (context.mounted) context.pop();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 280,
            child: FloatingActionButton(
              onPressed: () => context.push('/sos/${widget.tripId}'),
              backgroundColor: AppColors.sosRed,
              child: const Icon(Icons.emergency, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
