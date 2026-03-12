import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/chapa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  final String tripId;

  const SubscriptionScreen({super.key, required this.tripId});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'weekly';

  Future<void> _handleSubscribe() async {
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final user = authProvider.user;

    final amount = _selectedPlan == 'weekly' ? '180' : '650';

    final result = await paymentProvider.subscribeToTrip(
      context: context,
      tripId: widget.tripId,
      plan: _selectedPlan == 'weekly' ? 'Weekly' : 'Monthly',
      amount: amount,
      email: user?.email ?? 'user@ridelink.com',
      phone: user?.phone ?? '0911223344',
      firstName: user != null ? user.name.split(' ').first : 'User',
      lastName: user != null ? user.name.split(' ').last : '',
    );

    if (!mounted) return;

    if (result.result == ChapaPaymentResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription activated!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (result.result == ChapaPaymentResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscription),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Info',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Bole → Megenagna',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Mon-Fri 08:00 AM',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _selectedPlan = 'weekly'),
              child: AppCard(
                color: _selectedPlan == 'weekly'
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          l10n.weekly,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_selectedPlan == 'weekly')
                          const Icon(Icons.check_circle,
                              color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '5 trips per week • Best for regular commuters',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '180 ${l10n.etb}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '36 ${l10n.etb}/trip',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _selectedPlan = 'monthly'),
              child: AppCard(
                color: _selectedPlan == 'monthly'
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          l10n.monthly,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_selectedPlan == 'monthly')
                          const Icon(Icons.check_circle,
                              color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '20 trips per month • Save up to 25%',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '650 ${l10n.etb}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '32.50 ${l10n.etb}/trip',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: l10n.subscribe,
              isLoading: paymentProvider.processing,
              onPressed: _handleSubscribe,
            ),
          ],
        ),
      ),
    );
  }
}
