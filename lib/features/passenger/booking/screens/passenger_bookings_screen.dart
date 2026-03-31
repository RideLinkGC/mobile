import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../providers/booking_provider.dart';
import '../widgets/passenger_booking_card.dart';

class PassengerBookingsScreen extends StatefulWidget {
  const PassengerBookingsScreen({super.key});

  @override
  State<PassengerBookingsScreen> createState() => _PassengerBookingsScreenState();
}

class _PassengerBookingsScreenState extends State<PassengerBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadBookings();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<BookingProvider>().loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingProvider = context.watch<BookingProvider>();

    final activeBookings = bookingProvider.bookings
        .where((b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.pending)
        .toList();
    final pastBookings = bookingProvider.bookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellMenuButton(),
        title: const Text('Bookings'),
      ),
      body: bookingProvider.loading && bookingProvider.bookings.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Text(
                    'Active',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (activeBookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'No active bookings',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textHintLight,
                            ),
                      ),
                    )
                  else
                    ...activeBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PassengerBookingCard(
                          booking: booking,
                          l10n: l10n,
                          onTap: () =>
                              context.push('/driver-detail/${booking.tripId}'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Past trips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (pastBookings.isEmpty)
                    Text(
                      'No past trips yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textHintLight,
                          ),
                    )
                  else
                    ...pastBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PassengerBookingCard(
                          booking: booking,
                          l10n: l10n,
                          onTap: () =>
                              context.push('/driver-detail/${booking.tripId}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
