import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/location_search_field.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../models/trip_model.dart';
import '../models/trip_series_model.dart';
import '../providers/trip_series_provider.dart';

class CreateSeriesScreen extends StatefulWidget {
  const CreateSeriesScreen({super.key});

  @override
  State<CreateSeriesScreen> createState() => _CreateSeriesScreenState();
}

class _CreateSeriesScreenState extends State<CreateSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _weeklyPriceController = TextEditingController();
  final _monthlyPriceController = TextEditingController();

  GeocodingResult? _originResult;
  GeocodingResult? _destinationResult;

  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _seats = 4;
  bool _isLoading = false;

  final Set<int> _selectedDays = {1, 2, 3, 4, 5};
  bool _offerWeekly = true;
  bool _offerMonthly = true;

  static const _dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  void dispose() {
    _priceController.dispose();
    _weeklyPriceController.dispose();
    _monthlyPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (time != null) setState(() => _departureTime = time);
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originResult == null || _destinationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select origin and destination')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final timeStr =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

    final subOptions = <String>[];
    if (_offerWeekly) subOptions.add('weekly');
    if (_offerMonthly) subOptions.add('monthly');

    Map<String, double>? subPricing;
    if (subOptions.isNotEmpty) {
      subPricing = {};
      if (_offerWeekly && _weeklyPriceController.text.isNotEmpty) {
        subPricing['weekly'] = double.parse(_weeklyPriceController.text);
      }
      if (_offerMonthly && _monthlyPriceController.text.isNotEmpty) {
        subPricing['monthly'] = double.parse(_monthlyPriceController.text);
      }
    }

    final seriesData = TripSeriesModel(
      id: '',
      driverId: '',
      origin: _originResult!.name,
      destination: _destinationResult!.name,
      routeCoordinates: [
        RouteCoordinate(lat: _originResult!.lat, lng: _originResult!.lng),
        RouteCoordinate(
            lat: _destinationResult!.lat, lng: _destinationResult!.lng),
      ],
      distanceKm: 0,
      availableSeats: _seats,
      pricePerSeat: double.parse(_priceController.text),
      daysOfWeek: _selectedDays.toList()..sort(),
      departureTimeOfDay: timeStr,
      startDate: _startDate,
      endDate: _endDate,
      subscriptionOptions: subOptions
          .map((e) => e == 'monthly'
              ? SubscriptionType.monthly
              : SubscriptionType.weekly)
          .toList(),
      subscriptionPricing: subPricing,
    );

    final provider = context.read<TripSeriesProvider>();
    final success = await provider.createSeries(seriesData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring trip created!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create series'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Create Recurring Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LocationSearchField(
                hintText: 'Origin',
                prefixIcon: Icons.trip_origin,
                initialValue: _originResult?.name,
                onPlaceSelected: (r) => setState(() => _originResult = r),
              ),
              const SizedBox(height: 16),
              LocationSearchField(
                hintText: 'Destination',
                prefixIcon: Icons.location_on,
                initialValue: _destinationResult?.name,
                onPlaceSelected: (r) => setState(() => _destinationResult = r),
              ),
              const SizedBox(height: 24),
              Text('Days of Week',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _dayLabels.entries.map((e) {
                  final selected = _selectedDays.contains(e.key);
                  return FilterChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedDays.add(e.key);
                        } else {
                          _selectedDays.remove(e.key);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Departure Time',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(timeString),
              ),
              const SizedBox(height: 24),
              Text('Date Range',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEndDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'No end'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Seats', style: Theme.of(context).textTheme.titleMedium),
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
                    child: Text('$_seats',
                        style: Theme.of(context).textTheme.headlineMedium),
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
                hintText: 'Price per seat (ETB)',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price is required';
                  if (double.tryParse(v) == null) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text('Subscription Options',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Weekly'),
                value: _offerWeekly,
                onChanged: (v) => setState(() => _offerWeekly = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_offerWeekly)
                AppTextField(
                  controller: _weeklyPriceController,
                  hintText: 'Weekly price (ETB)',
                  prefixIcon: Icons.date_range,
                  keyboardType: TextInputType.number,
                ),
              SwitchListTile(
                title: const Text('Monthly'),
                value: _offerMonthly,
                onChanged: (v) => setState(() => _offerMonthly = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_offerMonthly)
                AppTextField(
                  controller: _monthlyPriceController,
                  hintText: 'Monthly price (ETB)',
                  prefixIcon: Icons.calendar_month,
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Create Recurring Trip',
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
