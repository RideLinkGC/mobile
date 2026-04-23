import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/chapa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../passenger/booking/providers/booking_provider.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.inApp;
  bool _showSuccess = false;
  BookingModel? _booking;
  bool _loadingBooking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooking());
  }

  Future<void> _loadBooking() async {
    final booking =
        await context.read<BookingProvider>().getBookingById(widget.bookingId);
    if (mounted) {
      setState(() {
        _booking = booking;
        _loadingBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentProvider = context.watch<PaymentProvider>();

    if (_loadingBooking) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.payment)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;
    final route = booking != null
        ? '${booking.tripOrigin ?? 'Origin'} → ${booking.tripDestination ?? 'Destination'}'
        : 'Trip';
    final departure = booking?.tripDepartureTime != null
        ? DateFormat.jm().format(booking!.tripDepartureTime!)
        : '--:--';
    final seats = booking?.seatsBooked ?? 1;
    final amount = booking?.totalPrice ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payment),
      ),
      body: _showSuccess
          ? _buildSuccessView(context, l10n)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Summary',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(route, 'Route'),
                        _buildSummaryRow(departure, 'Departure'),
                        _buildSummaryRow('$seats seat${seats > 1 ? 's' : ''}',
                            'Passengers'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${amount.toStringAsFixed(0)} ${l10n.etb}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Method',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _PaymentMethodTile(
                    method: PaymentMethod.inApp,
                    label: 'Chapa (Telebirr, CBEBirr, etc.)',
                    icon: Icons.credit_card,
                    isSelected: _selectedMethod == PaymentMethod.inApp,
                    onTap: () =>
                        setState(() => _selectedMethod = PaymentMethod.inApp),
                  ),
                  const SizedBox(height: 8),
                  _PaymentMethodTile(
                    method: PaymentMethod.cash,
                    label: 'Cash',
                    icon: Icons.payments,
                    isSelected: _selectedMethod == PaymentMethod.cash,
                    onTap: () =>
                        setState(() => _selectedMethod = PaymentMethod.cash),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: l10n.payNow,
                    isLoading: paymentProvider.processing,
                    onPressed: _handlePayNow,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: AppColors.success),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment has been processed successfully.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Done',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayNow() async {
    if (_selectedMethod == PaymentMethod.cash) {
      setState(() => _showSuccess = true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final user = authProvider.user;
    final amount = _booking?.totalPrice ?? 0;

    final result = await paymentProvider.payForTrip(
      context: context,
      bookingId: widget.bookingId,
      amount: amount.toStringAsFixed(0),
      email: user?.email ?? 'user@ridelink.com',
      phone: user?.phone ?? '0911223344',
      firstName: user != null ? user.name.split(' ').first : 'User',
      lastName: user != null ? user.name.split(' ').last : '',
    );

    if (!mounted) return;

    if (result.result == ChapaPaymentResult.success) {
      final status = await paymentProvider.getBookingPaymentStatus(widget.bookingId);
      if (!mounted) return;
      final paid = status?['paid'] == true;
      if (paid) {
        setState(() => _showSuccess = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment submitted. Waiting for verification.'),
          ),
        );
      }
    } else if (result.result == ChapaPaymentResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          Icon(icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryLight),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
        ],
      ),
    );
  }
}
