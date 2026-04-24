import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../models/passenger_booking_list_item.dart';
import '../providers/booking_provider.dart';
import '../widgets/passenger_booking_list_card.dart';

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
      if (!mounted) return;
      context.read<BookingProvider>().loadBookings();
    });
  }

  PassengerBookingListItem _toListItem(
    BookingModel booking,
    PassengerBookingListKind kind,
  ) {
    final driver = booking.driverName?.trim();
    return PassengerBookingListItem(
      id: booking.id,
      tripId: booking.tripId,
      driverName: (driver != null && driver.isNotEmpty) ? driver : 'Driver',
      origin: booking.tripOrigin ?? 'Unknown origin',
      destination: booking.tripDestination ?? 'Unknown destination',
      departureTime: booking.tripDepartureTime ?? DateTime.now(),
      totalPrice: booking.totalPrice,
      seatsBooked: booking.seatsBooked,
      kind: kind,
      isRecurrent: booking.isSubscription,
      recurrenceLabel: booking.isSubscription ? 'Subscription' : null,
    );
  }

  Future<void> _onRefresh() async {
    await context.read<BookingProvider>().loadBookings();
  }

  Future<void> _onCancel(PassengerBookingListItem item) async {
    final provider = context.read<BookingProvider>();
    final success = await provider.cancelBooking(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? AppLocalizations.of(context)!.bookingCancelledMessage
              : (provider.error ?? 'Failed to cancel booking'),
        ),
        backgroundColor: success ? null : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) {
      await provider.loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingProvider = context.watch<BookingProvider>();
    final bookings = bookingProvider.bookings;
    final pendingDriver = bookings
        .where((b) => b.status == BookingStatus.pending)
        .map((b) => _toListItem(
              b,
              PassengerBookingListKind.pendingDriverConfirmation,
            ))
        .toList();
    final active = bookings
        .where(
          (b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.completed,
        )
        .map((b) => _toListItem(b, PassengerBookingListKind.active))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellMenuButton(),
        title: Text(l10n.passengerBookingsTitle),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: bookingProvider.loading && bookings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: l10n.bookingSectionPendingDriver),
                  const SizedBox(height: 12),
                  ..._buildPendingList(l10n, pendingDriver),
                  const SizedBox(height: 28),
                  _SectionHeader(title: l10n.bookingSectionActive),
                  const SizedBox(height: 12),
                  ..._buildActiveList(l10n, active),
                  if (bookingProvider.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      bookingProvider.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPendingList(
    AppLocalizations l10n,
    List<PassengerBookingListItem> pendingDriver,
  ) {
    if (pendingDriver.isEmpty) {
      return [
        _EmptyHint(text: l10n.bookingEmptyPending),
      ];
    }
    return pendingDriver
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PassengerBookingListCard(
              item: item,
              l10n: l10n,
              onCancel: () => _onCancel(item),
              onTap: () => context.push('/passenger-trip-detail/${item.tripId}'),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildActiveList(
    AppLocalizations l10n,
    List<PassengerBookingListItem> active,
  ) {
    if (active.isEmpty) {
      return [
        _EmptyHint(text: l10n.bookingEmptyActive),
      ];
    }
    return active
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PassengerBookingListCard(
              item: item,
              l10n: l10n,
              onTap: () => context.push('/passenger-trip-detail/${item.tripId}'),
            ),
          ),
        )
        .toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHintLight,
            ),
      ),
    );
  }
}
