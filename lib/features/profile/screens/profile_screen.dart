import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shell_drawer_scope.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleModelController;
  late final TextEditingController _vehiclePlateController;
  late final TextEditingController _vehicleSeatsController;

  bool _editing = false;
  bool _saving = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: u?.name ?? '');
    _phoneController = TextEditingController(text: u?.phone ?? '');
    _vehicleModelController = TextEditingController(text: u?.vehicleModel ?? '');
    _vehiclePlateController = TextEditingController(text: u?.vehiclePlate ?? '');
    _vehicleSeatsController = TextEditingController(
      text: u?.vehicleSeats?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleSeatsController.dispose();
    super.dispose();
  }

  void _syncFromUser(UserModel u) {
    _nameController.text = u.name;
    _phoneController.text = u.phone;
    _vehicleModelController.text = u.vehicleModel ?? '';
    _vehiclePlateController.text = u.vehiclePlate ?? '';
    _vehicleSeatsController.text = u.vehicleSeats?.toString() ?? '';
  }

  void _cancelEdit() {
    final u = context.read<AuthProvider>().user;
    if (u != null) _syncFromUser(u);
    setState(() {
      _editing = false;
      _pickedImage = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _save() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileNamePhoneRequired)),
      );
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': name,
      'phone': phone,
    };

    if (user.isDriver) {
      data['vehicleModel'] = _vehicleModelController.text.trim();
      data['vehiclePlate'] = _vehiclePlateController.text.trim();
      final seats = int.tryParse(_vehicleSeatsController.text.trim());
      if (seats != null) data['vehicleSeats'] = seats;
    }

    authProvider.clearError();
    await authProvider.updateProfile(data);

    if (!mounted) return;
    final error = authProvider.errorMessage;
    setState(() {
      _saving = false;
      if (error == null) {
        _editing = false;
        _pickedImage = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? AppLocalizations.of(context)!.profileUpdatedSuccessfully),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _refreshProfile() async {
    await context.read<AuthProvider>().checkAuthStatus();
  }

  double _completionPercent(UserModel user) {
    final checks = <bool>[
      user.name.trim().isNotEmpty,
      user.phone.trim().isNotEmpty,
      user.email.trim().isNotEmpty,
      (user.image ?? '').trim().isNotEmpty,
      if (user.isDriver) (user.vehicleModel ?? '').trim().isNotEmpty,
      if (user.isDriver) (user.vehiclePlate ?? '').trim().isNotEmpty,
      if (user.isDriver) (user.vehicleSeats ?? 0) > 0,
    ];
    final completed = checks.where((it) => it).length;
    return checks.isEmpty ? 0 : completed / checks.length;
  }

  List<_ProfileActivityItem> _recentActivity(
    UserModel user,
    AppLocalizations l10n,
  ) {
    return <_ProfileActivityItem>[
      _ProfileActivityItem(
        icon: Icons.account_circle_outlined,
        title: l10n.profileActivityAccountCreated,
        subtitle: user.email,
      ),
      _ProfileActivityItem(
        icon: user.isDriver
            ? Icons.directions_car_filled_outlined
            : Icons.route_outlined,
        title: user.isDriver
            ? l10n.profileActivityDriverConfigured
            : l10n.profileActivityPassengerActive,
        subtitle: user.isDriver
            ? l10n.profileActivityVehicleDetails
            : l10n.profileActivityReadyToBook,
      ),
      _ProfileActivityItem(
        icon: Icons.shield_outlined,
        title: l10n.profileActivityIdentityVerification,
        subtitle: user.isActive
            ? l10n.profileStatusGoodStanding
            : l10n.profileStatusPendingVerificationDetails,
      ),
      _ProfileActivityItem(
        icon: Icons.notifications_none_rounded,
        title: l10n.notifications,
        subtitle: l10n.profileActivityManageAlerts,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const ShellMenuButton(),
              title: Text(l10n.profile),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final completion = _completionPercent(user);
        final activity = _recentActivity(user, l10n);

        return Scaffold(
          appBar: AppBar(
            leading: const ShellMenuButton(),
            title: Text(l10n.profile),
            actions: [
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editProfile,
                  onPressed: () => setState(() => _editing = true),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                  onPressed: _saving ? null : _cancelEdit,
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshProfile,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _editing
                  ? _EditBody(
                      key: const ValueKey('edit-mode'),
                      l10n: l10n,
                      user: user,
                      nameController: _nameController,
                      phoneController: _phoneController,
                      vehicleModelController: _vehicleModelController,
                      vehiclePlateController: _vehiclePlateController,
                      vehicleSeatsController: _vehicleSeatsController,
                      pickedImage: _pickedImage,
                      saving: _saving,
                      onPickImage: _pickImage,
                      onSave: _save,
                      onCancel: _cancelEdit,
                    )
                  : _ViewBody(
                      key: const ValueKey('view-mode'),
                      user: user,
                      l10n: l10n,
                      completion: completion,
                      activity: activity,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ViewBody extends StatelessWidget {
  final double completion;
  final List<_ProfileActivityItem> activity;
  final UserModel user;
  final AppLocalizations l10n;

  const _ViewBody({
    super.key,
    required this.user,
    required this.l10n,
    required this.completion,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final horizontalPadding = compact ? 16.0 : 20.0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 120),
      children: [
        _ProfileHeroCard(user: user, completion: completion, l10n: l10n),
        const SizedBox(height: 16),
        _StatsGrid(user: user, completion: completion, l10n: l10n),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.profilePersonalDetailsTitle,
          subtitle: l10n.profilePersonalDetailsSubtitle,
          child: Column(
            children: [
              _ReadRow(icon: Icons.email_outlined, label: l10n.email, value: user.email),
              const SizedBox(height: 16),
              _ReadRow(
                icon: Icons.phone_outlined,
                label: l10n.phoneNumber,
                value: user.phone,
              ),
              const SizedBox(height: 16),
              _ReadRow(
                icon: Icons.badge_outlined,
                label: l10n.nationalId,
                value: _maskedNationalId(user.nationalId, l10n),
              ),
            ],
          ),
        ),
        if (user.isDriver) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.profileDriverDetailsTitle,
            subtitle: l10n.profileDriverDetailsSubtitle,
            child: Column(
              children: [
                _ReadRow(
                  icon: Icons.directions_car_outlined,
                  label: l10n.vehicleModel,
                  value: user.vehicleModel ?? '',
                ),
                const SizedBox(height: 16),
                _ReadRow(
                  icon: Icons.badge_outlined,
                  label: l10n.vehiclePlate,
                  value: user.vehiclePlate ?? '',
                ),
                const SizedBox(height: 16),
                _ReadRow(
                  icon: Icons.event_seat_outlined,
                  label: l10n.vehicleSeats,
                  value: user.vehicleSeats?.toString() ?? '',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.profileQuickActionsTitle,
          subtitle: l10n.profileQuickActionsSubtitle,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.verified_user_outlined,
                label: l10n.verifyIdentity,
                onTap: () => context.push('/verification'),
              ),
              _ActionChip(
                icon: Icons.repeat_rounded,
                label: l10n.mySubscriptions,
                onTap: () => context.push('/my-subscriptions'),
              ),
              _ActionChip(
                icon: Icons.history,
                label: l10n.paymentHistory,
                onTap: () => context.push('/payment-history'),
              ),
              _ActionChip(
                icon: Icons.notifications_none_rounded,
                label: l10n.notifications,
                onTap: () => context.push('/notifications'),
              ),
              _ActionChip(
                icon: Icons.settings_outlined,
                label: l10n.settings,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.profileRecentActivityTitle,
          subtitle: l10n.profileRecentActivitySubtitle,
          child: activity.isEmpty
              ? _EmptyHint(
                  icon: Icons.timeline_rounded,
                  title: l10n.profileNoActivityTitle,
                  message: l10n.profileNoActivityMessage,
                )
              : Column(
                  children: [
                    for (var i = 0; i < activity.length; i++) ...[
                      _ActivityTile(item: activity[i]),
                      if (i != activity.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final UserModel user;
  final double completion;
  final AppLocalizations l10n;

  const _ProfileHeroCard({
    required this.user,
    required this.completion,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
                  theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.84),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.18),
                  theme.colorScheme.surface,
                ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarDisplay(user: user, radius: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(
                            icon: user.isDriver
                                ? Icons.directions_car_outlined
                                : Icons.person_outline_rounded,
                            label: _roleLabel(user.role.name, l10n),
                          ),
                          _MetaPill(
                            icon: user.isActive
                                ? Icons.verified_outlined
                                : Icons.pending_outlined,
                            label: user.isActive
                                ? l10n.profileStatusActive
                                : l10n.profileStatusPending,
                            positive: user.isActive,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: theme.colorScheme.surface.withValues(alpha: 0.86),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.profileCompletionLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(completion * 100).round()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final UserModel user;
  final double completion;
  final AppLocalizations l10n;

  const _StatsGrid({
    required this.user,
    required this.completion,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final stats = <_StatData>[
      _StatData(
        label: l10n.rating,
        value: user.rating.toStringAsFixed(1),
        icon: Icons.star_rounded,
        accent: AppColors.ratingStar,
      ),
      _StatData(
        label: l10n.profileRoleLabel,
        value: _roleLabel(user.role.name, l10n),
        icon: user.isDriver ? Icons.directions_car_outlined : Icons.person_outline,
        accent: AppColors.primary,
      ),
      _StatData(
        label: l10n.profileStatusLabel,
        value: user.isActive ? l10n.profileStatusActive : l10n.profileStatusPending,
        icon: user.isActive ? Icons.verified_outlined : Icons.pending_outlined,
        accent: user.isActive ? AppColors.success : AppColors.warning,
      ),
      _StatData(
        label: l10n.profile,
        value: '${(completion * 100).round()}%',
        icon: Icons.data_thresholding_outlined,
        accent: AppColors.primaryDark,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) => _StatCard(data: stats[index]),
    );
  }
}

class _ReadRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty
                      ? AppLocalizations.of(context)!.profileNotProvided
                      : value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarDisplay extends StatelessWidget {
  final UserModel user;
  final double radius;

  const _AvatarDisplay({required this.user, this.radius = 56});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: user.image != null && user.image!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.image!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const CircularProgressIndicator(color: AppColors.primary),
                errorWidget: (_, __, ___) => _placeholder(),
              ),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
      style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
    );
  }
}

class _EditBody extends StatelessWidget {
  final AppLocalizations l10n;
  final UserModel user;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController vehicleModelController;
  final TextEditingController vehiclePlateController;
  final TextEditingController vehicleSeatsController;
  final File? pickedImage;
  final bool saving;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditBody({
    super.key,
    required this.l10n,
    required this.user,
    required this.nameController,
    required this.phoneController,
    required this.vehicleModelController,
    required this.vehiclePlateController,
    required this.vehicleSeatsController,
    required this.pickedImage,
    required this.saving,
    required this.onPickImage,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _SectionCard(
          title: l10n.editProfile,
          subtitle: l10n.profileEditSubtitle,
          child: Column(
            children: [
              GestureDetector(
                onTap: onPickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                      child: pickedImage != null
                          ? ClipOval(
                              child: Image.file(
                                pickedImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : user.image != null && user.image!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.image!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        const CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                    errorWidget: (_, __, ___) => _ph(user),
                                  ),
                                )
                              : _ph(user),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.softElevated(context),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profilePhotoUploadPreview,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.profilePhotoSyncingNote,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.profileBasicInformationTitle,
          subtitle: l10n.profileBasicInformationSubtitle,
          child: Column(
            children: [
              AppTextField(
                controller: nameController,
                labelText: l10n.fullName,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: phoneController,
                labelText: l10n.phoneNumber,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        if (user.isDriver) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.profileVehicleInformationTitle,
            subtitle: l10n.profileVehicleInformationSubtitle,
            child: Column(
              children: [
                AppTextField(
                  controller: vehicleModelController,
                  labelText: l10n.vehicleModel,
                  prefixIcon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: vehiclePlateController,
                  labelText: l10n.vehiclePlate,
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: vehicleSeatsController,
                  labelText: l10n.vehicleSeats,
                  prefixIcon: Icons.event_seat_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(saving ? l10n.profileSaving : l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ph(UserModel user) {
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
      style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: AppShadows.softCard(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool positive;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = positive ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: data.accent),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(data.label, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ProfileActivityItem item;

  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(message, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
}

class _ProfileActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

String _maskedNationalId(String nationalId, AppLocalizations l10n) {
  if (nationalId.trim().isEmpty) return l10n.profileNotProvided;
  final compact = nationalId.trim();
  if (compact.length <= 4) return compact;
  final suffix = compact.substring(compact.length - 4);
  return '••••••$suffix';
}

String _roleLabel(String role, AppLocalizations l10n) {
  if (role.isEmpty) return l10n.profileUserLabel;
  return '${role[0].toUpperCase()}${role.substring(1)}';
}
