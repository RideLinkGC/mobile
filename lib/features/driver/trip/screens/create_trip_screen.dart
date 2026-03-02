import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/location_search_field.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _weeklyPriceController = TextEditingController();
  final _monthlyPriceController = TextEditingController();

  GeocodingResult? _originResult;
  GeocodingResult? _destinationResult;
  RouteResult? _route;

  DateTime _departureDate = DateTime.now();
  TimeOfDay _departureTime = TimeOfDay.now();
  int _seats = 1;
  bool _allowSubscriptions = false;
  bool _isLoading = false;
  bool _pickingOrigin = true;

  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey();

  @override
  void dispose() {
    _priceController.dispose();
    _weeklyPriceController.dispose();
    _monthlyPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) setState(() => _departureDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (time != null) setState(() => _departureTime = time);
  }

  void _onMapTap(LatLng latLng) async {
    final mapsService = context.read<GebetaMapsService>();
    final result = await mapsService.reverseGeocode(
      latLng.latitude,
      latLng.longitude,
    );

    if (!mounted || result == null) return;

    setState(() {
      if (_pickingOrigin) {
        _originResult = result;
        _pickingOrigin = false;
      } else {
        _destinationResult = result;
      }
    });

    _tryLoadRoute();
  }

  Future<void> _tryLoadRoute() async {
    if (_originResult == null || _destinationResult == null) return;

    final mapsService = context.read<GebetaMapsService>();
    final route = await mapsService.getRoute(
      originLat: _originResult!.lat,
      originLng: _originResult!.lng,
      destLat: _destinationResult!.lat,
      destLng: _destinationResult!.lng,
    );
    if (mounted) {
      setState(() => _route = route);
    }
  }

  List<MapMarker> get _markers {
    final markers = <MapMarker>[];
    if (_originResult != null) {
      markers.add(MapMarker(
        position: LatLng(_originResult!.lat, _originResult!.lng),
      ));
    }
    if (_destinationResult != null) {
      markers.add(MapMarker(
        position: LatLng(_destinationResult!.lat, _destinationResult!.lng),
      ));
    }
    return markers;
  }

  List<MapPolyline> get _polylines {
    if (_route == null) return [];
    final points = _route!.polylinePoints
        .map((p) => LatLng(p[0], p[1]))
        .toList();
    return [MapPolyline(points: points, color: '#188AEC', width: 4)];
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originResult == null || _destinationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select origin and destination on the map or via search')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip created successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeString =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createTrip)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: GebetaMapWidget(
                    key: _mapKey,
                    initialZoom: 13,
                    onTap: _onMapTap,
                    markers: _markers,
                    polylines: _polylines,
                    showUserLocation: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pickingOrigin
                    ? 'Tap the map to set origin'
                    : _destinationResult == null
                        ? 'Tap the map to set destination'
                        : 'Route set! Adjust below if needed.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LocationSearchField(
                hintText: l10n.origin,
                prefixIcon: Icons.trip_origin,
                initialValue: _originResult?.name,
                onPlaceSelected: (result) {
                  setState(() => _originResult = result);
                  _tryLoadRoute();
                },
              ),
              const SizedBox(height: 16),
              LocationSearchField(
                hintText: l10n.destination,
                prefixIcon: Icons.location_on,
                initialValue: _destinationResult?.name,
                onPlaceSelected: (result) {
                  setState(() => _destinationResult = result);
                  _tryLoadRoute();
                },
              ),
              if (_route != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_route!.distanceKm.toStringAsFixed(1)} km · ${_route!.durationMinutes.toStringAsFixed(0)} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Text(l10n.departureTime,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(dateString),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(timeString),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.seats, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filled(
                    onPressed:
                        _seats > 1 ? () => setState(() => _seats--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$_seats',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _seats < AppConstants.maxVehicleSeats
                        ? () => setState(() => _seats++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _priceController,
                hintText: '${l10n.pricePerSeat} (${l10n.etb})',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price is required';
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Max ${AppConstants.maxPricePerKmPerSeat} ${l10n.etb}/${l10n.km}/seat',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondaryLight),
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(l10n.subscription),
                subtitle: const Text('Allow weekly/monthly subscriptions'),
                value: _allowSubscriptions,
                onChanged: (v) => setState(() => _allowSubscriptions = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_allowSubscriptions) ...[
                const SizedBox(height: 8),
                AppTextField(
                  controller: _weeklyPriceController,
                  hintText: '${l10n.weekly} price (${l10n.etb})',
                  prefixIcon: Icons.date_range,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _monthlyPriceController,
                  hintText: '${l10n.monthly} price (${l10n.etb})',
                  prefixIcon: Icons.calendar_month,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: l10n.createTrip,
                onPressed: _handleSubmit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
