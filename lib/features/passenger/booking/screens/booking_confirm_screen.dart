import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gebeta_map_widget.dart';
import '../../../../core/widgets/location_search_field.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../driver/trip/providers/trip_provider.dart';
import '../providers/booking_provider.dart';

class BookingConfirmScreen extends StatefulWidget {
  final String tripId;

  const BookingConfirmScreen({super.key, required this.tripId});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _isConfirming = false;

  GeocodingResult? _pickupResult;
  GeocodingResult? _dropoffResult;

  final _pickupLatLng = const LatLng(9.0192, 38.7525);
  final _dropoffLatLng = const LatLng(9.0300, 38.7800);

  static const int _seats = 1;
  static const int _platformFee = 5;

  List<MapMarker> get _markers {
    final pickup = _pickupResult != null
        ? LatLng(_pickupResult!.lat, _pickupResult!.lng)
        : _pickupLatLng;
    final dropoff = _dropoffResult != null
        ? LatLng(_dropoffResult!.lat, _dropoffResult!.lng)
        : _dropoffLatLng;
    return [
      MapMarker(position: pickup),
      MapMarker(position: dropoff),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().getTripById(widget.tripId);
    });
  }

  Future<void> _onConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.read<TripProvider>();
    final storageService = context.read<StorageService>();
    final bookingProvider = context.read<BookingProvider>();

    final trip = tripProvider.selectedTrip;
    if (trip == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip not found')),
        );
      }
      return;
    }

    final passengerId = await storageService.getPassengerId();
    if (passengerId == null || passengerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to book a ride')),
        );
      }
      return;
    }

    setState(() => _isConfirming = true);

    final pickUpPoint = _pickupResult?.name ?? trip.origin;
    final dropOffPoint = _dropoffResult?.name ?? trip.destination;
    final totalPrice = trip.pricePerSeat * _seats;

    final success = await bookingProvider.requestBooking(
          tripId: widget.tripId,
          passengerId: passengerId,
          seatsBooked: _seats,
          totalPrice: totalPrice,
          pickUpPoint: pickUpPoint,
          dropOffPoint: dropOffPoint,
        );

    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.bookingConfirmed),
          content: const Text(
            'Your booking has been confirmed. The driver will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/passenger');
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingProvider.error ?? 'Failed to request booking',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.selectedTrip;

    if (trip == null && !tripProvider.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookRide)),
        body: const Center(child: Text('Trip not found')),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookRide)),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final subtotal = trip.pricePerSeat * _seats;
    final total = subtotal + _platformFee;
    final departureFormatted = DateFormat.jm().format(trip.departureTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookRide),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: GebetaMapWidget(
                  initialCenter: _pickupLatLng,
                  initialZoom: 13,
                  interactive: false,
                  markers: _markers,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    trip.driverName ?? 'Driver',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${trip.origin} → ${trip.destination}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        departureFormatted,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LocationSearchField(
              hintText: 'Pickup Point',
              prefixIcon: Icons.location_on_outlined,
              initialValue: trip.origin,
              onPlaceSelected: (result) {
                setState(() => _pickupResult = result);
              },
            ),
            const SizedBox(height: 16),
            LocationSearchField(
              hintText: 'Dropoff Point',
              prefixIcon: Icons.location_on_outlined,
              initialValue: trip.destination,
              onPlaceSelected: (result) {
                setState(() => _dropoffResult = result);
              },
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Breakdown',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _PriceRow(
                    label:
                        '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb} × $_seats ${l10n.seats}',
                    value: '$subtotal ${l10n.etb}',
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: 'Platform fee',
                    value: '$_platformFee ${l10n.etb}',
                  ),
                  const Divider(height: 24),
                  _PriceRow(
                    label: 'Total',
                    value: '$total ${l10n.etb}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.confirm,
              onPressed: _isConfirming ? null : _onConfirm,
              isLoading: _isConfirming,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
