import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/rating_widget.dart';
import '../../../core/widgets/shell_drawer_scope.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _vehicleSeatsController;

  bool _editing = false;
  bool _loading = false;
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

    setState(() => _loading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    if (user.isDriver) {
      data['vehicleModel'] = _vehicleModelController.text.trim();
      data['vehiclePlate'] = _vehiclePlateController.text.trim();
      final seats = int.tryParse(_vehicleSeatsController.text.trim());
      if (seats != null) data['vehicleSeats'] = seats;
    }

    await authProvider.updateProfile(data);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _editing = false;
      _pickedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

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
                  onPressed: _loading ? null : _cancelEdit,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _editing
                ? _EditBody(
                    l10n: l10n,
                    user: user,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    vehicleModelController: _vehicleModelController,
                    vehiclePlateController: _vehiclePlateController,
                    vehicleSeatsController: _vehicleSeatsController,
                    pickedImage: _pickedImage,
                    loading: _loading,
                    onPickImage: _pickImage,
                    onSave: _save,
                  )
                : _ViewBody(user: user, l10n: l10n),
          ),
        );
      },
    );
  }
}

class _ViewBody extends StatelessWidget {
  final UserModel user;
  final AppLocalizations l10n;

  const _ViewBody({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _AvatarDisplay(user: user)),
        const SizedBox(height: 20),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 20),
        _ReadRow(icon: Icons.email_outlined, label: l10n.email, value: user.email),
        const SizedBox(height: 12),
        _ReadRow(icon: Icons.phone_outlined, label: l10n.phoneNumber, value: user.phone),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppRatingWidget(rating: user.rating, size: 20),
            const SizedBox(width: 8),
            Text(
              user.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        if (user.isDriver) ...[
          const SizedBox(height: 24),
          if (user.vehicleModel != null && user.vehicleModel!.isNotEmpty)
            _ReadRow(
              icon: Icons.directions_car_outlined,
              label: l10n.vehicleModel,
              value: user.vehicleModel!,
            ),
          if (user.vehiclePlate != null && user.vehiclePlate!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ReadRow(
              icon: Icons.badge_outlined,
              label: l10n.vehiclePlate,
              value: user.vehiclePlate!,
            ),
          ],
          if (user.vehicleSeats != null) ...[
            const SizedBox(height: 12),
            _ReadRow(
              icon: Icons.event_seat_outlined,
              label: l10n.vehicleSeats,
              value: '${user.vehicleSeats}',
            ),
          ],
        ],
      ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '—' : value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarDisplay extends StatelessWidget {
  final UserModel user;

  const _AvatarDisplay({required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
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
  final bool loading;
  final VoidCallback onPickImage;
  final VoidCallback onSave;

  const _EditBody({
    required this.l10n,
    required this.user,
    required this.nameController,
    required this.phoneController,
    required this.vehicleModelController,
    required this.vehiclePlateController,
    required this.vehicleSeatsController,
    required this.pickedImage,
    required this.loading,
    required this.onPickImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: pickedImage != null
                      ? ClipOval(
                          child: Image.file(
                            pickedImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : user.image != null && user.image!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.image!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) => _ph(user),
                              ),
                            )
                          : _ph(user),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.softElevated(context),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: nameController,
          labelText: l10n.fullName,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: phoneController,
          labelText: l10n.phoneNumber,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        if (user.isDriver) ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: vehicleModelController,
            labelText: l10n.vehicleModel,
            prefixIcon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: vehiclePlateController,
            labelText: l10n.vehiclePlate,
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: vehicleSeatsController,
            labelText: l10n.vehicleSeats,
            prefixIcon: Icons.event_seat_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 32),
        AppButton(
          text: l10n.save,
          onPressed: loading ? null : onSave,
          isLoading: loading,
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
