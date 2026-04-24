import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/features/driver/common/driver_app_bar.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/location_search_field.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/trip_provider.dart';

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
  final Set<int> _selectedWeekdays = <int>{};
  final Set<String> _selectedDailySlots = <String>{};

  final GlobalKey<GebetaMapWidgetState> _mapKey = GlobalKey();
  static const List<(int, int)> _commutingWindows = [
    (6, 10),
    (17, 20),
  ];
  static final RegExp _uuidV4Like = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static const List<(int, String)> _availableWeekdays = [
    (DateTime.monday, 'Monday'),
    (DateTime.tuesday, 'Tuesday'),
    (DateTime.wednesday, 'Wednesday'),
    (DateTime.thursday, 'Thursday'),
    (DateTime.friday, 'Friday'),
    (DateTime.saturday, 'Saturday'),
    (DateTime.sunday, 'Sunday'),
  ];
  static const List<(String, String)> _dailyTripSlots = [
    ('morning', 'Morning trip'),
    ('lunch', 'Lunch time trip'),
    ('afternoon', 'Afternoon trip'),
  ];

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
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
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
    return [MapPolyline(points: points, color: AppColors.primaryMapHex, width: 4)];
  }

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    return _uuidV4Like.hasMatch(value.trim());
  }

  Future<String?> _resolveDriverId() async {
    final storage = context.read<StorageService>();
    final auth = context.read<AuthProvider>();

    final authDriverId = auth.user?.driverId?.trim();
    if (_isValidUuid(authDriverId)) return authDriverId;

    final storedDriverId = (await storage.getDriverId())?.trim();
    if (_isValidUuid(storedDriverId)) return storedDriverId;

    final cachedUserJson = await storage.getCachedUserJson();
    if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
      try {
        final map = jsonDecode(cachedUserJson) as Map<String, dynamic>;
        final cachedDriverId = (map['driverId'] as String?)?.trim();
        if (_isValidUuid(cachedDriverId)) return cachedDriverId;
      } catch (_) {
        // Ignore malformed cache and continue with null.
      }
    }

    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_allowSubscriptions) {
      if (_selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select at least one weekly day for subscriptions'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_selectedDailySlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select at least one daily trip time for subscriptions'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    if (_originResult == null || _destinationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select origin and destination on the map or via search',
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_route == null || _route!.polylinePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A valid route with at least two points is required'),
          backgroundColor: Color.fromARGB(255, 190, 163, 161),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    final driverId = await _resolveDriverId();
    if (!mounted) return;
    if (driverId == null || driverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Driver profile is missing. Please complete driver setup, then try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<TripProvider>();
    final origin = _originResult!.name;
    final destination = _destinationResult!.name;
    final routeCoordinates = _route != null
        ? _route!.polylinePoints
            .map((p) => {'lat': (p[0] as num).toDouble(), 'lng': (p[1] as num).toDouble()})
            .toList()
        : <Map<String, double>>[];
    final distanceKm = _route?.distanceKm ?? 0.0;
    final departureTime = DateTime(
      _departureDate.year,
      _departureDate.month,
      _departureDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );
    final pricePerSeat = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final now = DateTime.now();
    if (!departureTime.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Departure time must be in the future'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    final hour = departureTime.hour;
    final isInCommutingWindow = _commutingWindows.any(
      (window) => hour >= window.$1 && hour < window.$2,
    );
    if (!isInCommutingWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Departure must be within 06:00-10:00 or 17:00-20:00'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
 

    final createdTripId = await provider.createTrip(
      driverId: driverId,
      origin: origin,
      destination: destination,
      routeCoordinates: routeCoordinates,
      distanceKm: distanceKm,
      departureTime: departureTime,
      availableSeats: _seats,
      pricePerSeat: pricePerSeat,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (createdTripId != null && createdTripId.isNotEmpty) {
      await provider.loadDriverTrips();
      if (!mounted) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/trip-detail/$createdTripId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create trip'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeString =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}';

    return Scaffold(
      appBar: driverAppBarWitDrawer(context, l10n.createTrip, true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
              ),
              const SizedBox(height: 10),
              Text(
                _pickingOrigin
                    ? 'Step 1: tap the map to set origin'
                    : _destinationResult == null
                        ? 'Step 2: tap the map to set destination'
                        : 'Route ready — review details below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Route',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    LocationSearchField(
                      hintText: l10n.origin,
                      prefixIcon: Icons.trip_origin,
                      initialValue: _originResult?.name,
                      onPlaceSelected: (result) {
                        setState(() => _originResult = result);
                        _tryLoadRoute();
                      },
                    ),
                    const SizedBox(height: 14),
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
                      const SizedBox(height: 10),
                      Text(
                        '${_route!.distanceKm.toStringAsFixed(1)} ${l10n.km} · ${_route!.durationMinutes.toStringAsFixed(0)} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Schedule',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 10),
                    Text(
                      'Commute windows: 06:00–10:00 and 17:00–20:00',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Capacity & pricing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.seats,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
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
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _priceController,
                      hintText: '${l10n.pricePerSeat} (${l10n.etb})',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Price is required';
                        final price = double.tryParse(v);
                        if (price == null || price <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Max ${AppConstants.maxPricePerKmPerSeat} ${l10n.etb}/${l10n.km}/seat',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Subscriptions (optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      title: Text(l10n.subscription),
                      subtitle: const Text('Allow weekly/monthly subscriptions'),
                      value: _allowSubscriptions,
                      onChanged: (v) => setState(() {
                        _allowSubscriptions = v;
                        if (!v) {
                          _selectedWeekdays.clear();
                          _selectedDailySlots.clear();
                        }
                      }),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_allowSubscriptions) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Available weekdays',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      GridView.builder(
                        itemCount: _availableWeekdays.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.9,
                        ),
                        itemBuilder: (context, index) {
                          final day = _availableWeekdays[index];
                          return CheckboxListTile(
                            value: _selectedWeekdays.contains(day.$1),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedWeekdays.add(day.$1);
                                } else {
                                  _selectedWeekdays.remove(day.$1);
                                }
                              });
                            },
                            title: Text(day.$2),
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Available daily trip times',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      ..._dailyTripSlots.map(
                        (slot) => CheckboxListTile(
                          value: _selectedDailySlots.contains(slot.$1),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedDailySlots.add(slot.$1);
                              } else {
                                _selectedDailySlots.remove(slot.$1);
                              }
                            });
                          },
                          title: Text(slot.$2),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
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
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
