import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/rating_widget.dart';
import '../../../core/widgets/shell_drawer_scope.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../driver/trip/providers/trip_provider.dart';
import '../../passenger/booking/providers/booking_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: const ShellMenuButton(),
            title: Text(l10n.profile),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 24),
                  _ProfileInfoSection(user: user, l10n: l10n),
                  if (user.isPending) ...[
                    const SizedBox(height: 16),
                    _VerificationBanner(),
                  ],
                  if (user.isDriver) ...[
                    const SizedBox(height: 16),
                    _DriverStatsSection(user: user, l10n: l10n),
                  ],
                  if (user.isPassenger) ...[
                    const SizedBox(height: 16),
                    _PassengerStatsSection(user: user, l10n: l10n),
                  ],
                  const SizedBox(height: 24),
                  _ActionButtons(l10n: l10n, authProvider: authProvider),
                ],
              ),
            ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: user.image != null && user.image!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.image!,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const CircularProgressIndicator(color: AppColors.primary),
                      errorWidget: (_, __, ___) => _buildPlaceholderAvatar(),
                    ),
                  )
                : _buildPlaceholderAvatar(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
              child:
                  const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
      style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  final UserModel user;
  final AppLocalizations l10n;

  const _ProfileInfoSection({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              user.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.email_outlined, text: user.email),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.phone_outlined, text: user.phone),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppRatingWidget(rating: user.rating, size: 18),
              const SizedBox(width: 8),
              Text(
                user.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _DriverStatsSection extends StatelessWidget {
  final UserModel user;
  final AppLocalizations l10n;

  const _DriverStatsSection({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trips = tripProvider.driverTrips;
    final totalTrips = trips.length;
    final completedTrips =
        trips.where((t) => t.status == TripStatus.completed).toList();
    final earnings = completedTrips.fold<double>(
        0, (sum, t) => sum + t.pricePerSeat * t.bookedSeats);

    final vehicleInfo = [
      if (user.vehicleModel != null) user.vehicleModel!,
      if (user.vehiclePlate != null) user.vehiclePlate!,
    ].join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vehicleInfo.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.directions_car, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(vehicleInfo, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                  label: l10n.totalTrips,
                  value: '$totalTrips'),
              _StatItem(
                  label: l10n.earnings,
                  value: '${earnings.toStringAsFixed(0)} ${l10n.etb}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerStatsSection extends StatelessWidget {
  final UserModel user;
  final AppLocalizations l10n;

  const _PassengerStatsSection({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final totalBookings = bookingProvider.bookings.length;

    final routes = user.preferredRoutes ?? [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.preferredRoutes, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (routes.isEmpty)
            Text(
              '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHintLight,
                  ),
            )
          else
            ...routes.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.route, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
          _StatItem(
              label: l10n.totalTrips,
              value: '$totalBookings'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/verification'),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_outlined,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Verification',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upload your documents to unlock all features',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppLocalizations l10n;
  final AuthProvider authProvider;

  const _ActionButtons({
    required this.l10n,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          text: l10n.editProfile,
          icon: Icons.edit_outlined,
          onPressed: () => context.push('/edit-profile'),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Verify Identity',
          icon: Icons.verified_user_outlined,
          isOutlined: true,
          onPressed: () => context.push('/verification'),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'My Subscriptions',
          icon: Icons.repeat,
          isOutlined: true,
          onPressed: () => context.push('/my-subscriptions'),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: l10n.paymentHistory,
          icon: Icons.history,
          isOutlined: true,
          onPressed: () => context.push('/payment-history'),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: l10n.settings,
          icon: Icons.settings_outlined,
          isOutlined: true,
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: l10n.logout,
          icon: Icons.logout,
          isOutlined: true,
          foregroundColor: AppColors.error,
          onPressed: () async {
            await authProvider.logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }
}
