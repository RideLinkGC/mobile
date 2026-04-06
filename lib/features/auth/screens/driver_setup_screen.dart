import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class DriverSetupScreen extends StatefulWidget {
  const DriverSetupScreen({super.key});

  @override
  State<DriverSetupScreen> createState() => _DriverSetupScreenState();
}

class _DriverSetupScreenState extends State<DriverSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleSeatsController = TextEditingController();
  final _licenseDocumentIdController = TextEditingController();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleSeatsController.dispose();
    _licenseDocumentIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.becomeDriver(
      licenseNumber: _licenseNumberController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim(),
      vehicleSeats: int.parse(_vehicleSeatsController.text.trim()),
      licenseDocumentId: _licenseDocumentIdController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      context.go('/register/driver-documents');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to submit driver details'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loading = auth.state == AuthState.loading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: loading ? null : () => context.go('/register'),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: loading,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                  controller: _licenseNumberController,
                  hintText: 'License Number',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => Validators.required(v, 'License number'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _vehicleModelController,
                  hintText: 'Vehicle Model',
                  prefixIcon: Icons.directions_car_outlined,
                  validator: (v) => Validators.required(v, 'Vehicle model'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _vehiclePlateController,
                  hintText: 'Vehicle Plate Number',
                  prefixIcon: Icons.confirmation_number_outlined,
                  validator: Validators.vehiclePlate,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _vehicleSeatsController,
                  hintText: 'Vehicle Seats',
                  prefixIcon: Icons.event_seat_outlined,
                  keyboardType: TextInputType.number,
                  validator: Validators.seats,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _licenseDocumentIdController,
                  hintText: 'License Document ID',
                  prefixIcon: Icons.description_outlined,
                  validator: (v) =>
                      Validators.required(v, 'License document ID'),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Continue',
                  onPressed: _submit,
                  isLoading: loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DriverDocumentsScreen extends StatelessWidget {
  const DriverDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nextRoute = auth.isDriver ? '/driver' : '/login';
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Upload your documents now, or skip and do it later in Settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _UploadPlaceholderCard(
              title: 'Driver License Document',
              subtitle: 'Upload image or PDF',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _UploadPlaceholderCard(
              title: 'National ID / Passport',
              subtitle: 'Upload image or PDF',
              icon: Icons.perm_identity_outlined,
            ),
            const SizedBox(height: 28),
            AppButton(
              text: 'Skip for now',
              isOutlined: true,
              onPressed: () => context.go(nextRoute),
            ),
            const SizedBox(height: 10),
            AppButton(
              text: 'Continue',
              onPressed: () => context.go(nextRoute),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadPlaceholderCard extends StatelessWidget {
  const _UploadPlaceholderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File upload will be added next.')),
            );
          },
          child: const Text('Upload'),
        ),
      ),
    );
  }
}
