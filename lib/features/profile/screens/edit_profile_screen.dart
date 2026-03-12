import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleModelController;
  late final TextEditingController _vehiclePlateController;
  late final TextEditingController _vehicleSeatsController;
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _vehicleModelController = TextEditingController(text: user?.vehicleModel ?? '');
    _vehiclePlateController = TextEditingController(text: user?.vehiclePlate ?? '');
    _vehicleSeatsController = TextEditingController(
      text: user?.vehicleSeats?.toString() ?? '',
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isLoading = true);

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
    setState(() => _isLoading = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.editProfile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfilePhotoPicker(
                user: user,
                pickedImage: _pickedImage,
                onTap: _pickImage,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                labelText: l10n.fullName,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                labelText: l10n.phoneNumber,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              if (user.isDriver) ...[
                const SizedBox(height: 16),
                AppTextField(
                  controller: _vehicleModelController,
                  labelText: l10n.vehicleModel,
                  prefixIcon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _vehiclePlateController,
                  labelText: l10n.vehiclePlate,
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _vehicleSeatsController,
                  labelText: l10n.vehicleSeats,
                  prefixIcon: Icons.event_seat_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: l10n.save,
                onPressed: _isLoading ? null : _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  final UserModel user;
  final File? pickedImage;
  final VoidCallback onTap;

  const _ProfilePhotoPicker({
    required this.user,
    required this.pickedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                            placeholder: (_, __) => const CircularProgressIndicator(),
                            errorWidget: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
      style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
    );
  }
}
