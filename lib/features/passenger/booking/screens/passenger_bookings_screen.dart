import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shell_drawer_scope.dart';
import '../data/passenger_bookings_mock.dart';
import '../models/passenger_booking_list_item.dart';
import '../widgets/passenger_booking_list_card.dart';

class PassengerBookingsScreen extends StatefulWidget {
  const PassengerBookingsScreen({super.key});

  @override
  State<PassengerBookingsScreen> createState() => _PassengerBookingsScreenState();
}

class _PassengerBookingsScreenState extends State<PassengerBookingsScreen> {
  late List<PassengerBookingListItem> _awaitingYou;
  late List<PassengerBookingListItem> _pendingDriver;
  late List<PassengerBookingListItem> _active;

  @override
  void initState() {
    super.initState();
    _loadMock();
  }

  void _loadMock() {
    _awaitingYou = List<PassengerBookingListItem>.from(
      PassengerBookingsMock.awaitingYou(),
    );
    _pendingDriver = List<PassengerBookingListItem>.from(
      PassengerBookingsMock.pendingDriver(),
    );
    _active = List<PassengerBookingListItem>.from(
      PassengerBookingsMock.active(),
    );
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(_loadMock);
  }

  void _onAccept(PassengerBookingListItem item) {
    setState(() {
      _awaitingYou.removeWhere((e) => e.id == item.id);
      _active.insert(
        0,
        PassengerBookingListItem(
          id: item.id,
          tripId: item.tripId,
          driverName: item.driverName,
          origin: item.origin,
          destination: item.destination,
          departureTime: item.departureTime,
          totalPrice: item.totalPrice,
          seatsBooked: item.seatsBooked,
          kind: PassengerBookingListKind.active,
        ),
      );
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.bookingAcceptedMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onCancelAwaiting(PassengerBookingListItem item) {
    setState(() {
      _awaitingYou.removeWhere((e) => e.id == item.id);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.bookingCancelledMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const ShellMenuButton(),
        title: Text(l10n.passengerBookingsTitle),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  
                  _SectionHeader(title: l10n.bookingSectionPendingDriver),
                  const SizedBox(height: 12),
                  ..._buildPendingList(l10n),
                  const SizedBox(height: 28),
                  _SectionHeader(title: l10n.bookingSectionActive),
                  const SizedBox(height: 12),
                  ..._buildActiveList(l10n),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAwaitingList(AppLocalizations l10n) {
    if (_awaitingYou.isEmpty) {
      return [
        _EmptyHint(text: l10n.bookingEmptyAwaiting),
      ];
    }
    return _awaitingYou
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PassengerBookingListCard(
              item: item,
              l10n: l10n,
              onAccept: () => _onAccept(item),
              onCancel: () => _onCancelAwaiting(item),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildPendingList(AppLocalizations l10n) {
    if (_pendingDriver.isEmpty) {
      return [
        _EmptyHint(text: l10n.bookingEmptyPending),
      ];
    }
    return _pendingDriver
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PassengerBookingListCard(
              item: item,
              l10n: l10n,
              onTap: () => context.push('/driver-detail/${item.tripId}'),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildActiveList(AppLocalizations l10n) {
    if (_active.isEmpty) {
      return [
        _EmptyHint(text: l10n.bookingEmptyActive),
      ];
    }
    return _active
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PassengerBookingListCard(
              item: item,
              l10n: l10n,
              onTap: () => context.push('/driver-detail/${item.tripId}'),
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
