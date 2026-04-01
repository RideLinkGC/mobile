import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleSeatsController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.passenger;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleSeatsController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      vehicleModel: _selectedRole == UserRole.driver ? _vehicleModelController.text.trim() : null,
      vehiclePlate: _selectedRole == UserRole.driver ? _vehiclePlateController.text.trim() : null,
      vehicleSeats: _selectedRole == UserRole.driver ? int.tryParse(_vehicleSeatsController.text) : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.state == AuthState.loading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: Text(l10n.register),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  setState(() => _currentStep = 1);
                } else if (_currentStep == 1) {
                  if (_selectedRole == UserRole.driver) {
                    setState(() => _currentStep = 2);
                  } else {
                    _handleRegister();
                  }
                } else {
                  _handleRegister();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                final isLastStep = (_selectedRole == UserRole.passenger && _currentStep == 1)
                    || _currentStep == 2;
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: isLastStep ? l10n.submit : l10n.next,
                          onPressed: details.onStepContinue,
                          isLoading: isLoading,
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'Back',
                            onPressed: details.onStepCancel,
                            isOutlined: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text(l10n.selectRole),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      _RoleCard(
                        icon: Icons.person,
                        title: l10n.passenger,
                        description: 'Find affordable rides for your daily commute',
                        isSelected: _selectedRole == UserRole.passenger,
                        onTap: () => setState(() {
                          _selectedRole = UserRole.passenger;
                          if (_currentStep > 1) _currentStep = 1;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        icon: Icons.directions_car,
                        title: l10n.driver,
                        description: 'Share your ride and offset travel costs',
                        isSelected: _selectedRole == UserRole.driver,
                        onTap: () => setState(() => _selectedRole = UserRole.driver),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Personal Information'),
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                      AppTextField(
                        controller: _nameController,
                        hintText: l10n.fullName,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => Validators.required(v, 'Name'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailController,
                        hintText: l10n.email,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phoneController,
                        hintText: l10n.phoneNumber,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phoneNumber,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        hintText: l10n.password,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textHintLight,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Vehicle Information'),
                  isActive: _currentStep >= 2,
                  state: _selectedRole == UserRole.driver
                      ? StepState.indexed
                      : StepState.disabled,
                  content: Column(
                    children: [
                      AppTextField(
                        controller: _vehicleModelController,
                        hintText: l10n.vehicleModel,
                        prefixIcon: Icons.directions_car_outlined,
                        validator: (v) => Validators.required(v, 'Vehicle model'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _vehiclePlateController,
                        hintText: l10n.vehiclePlate,
                        prefixIcon: Icons.confirmation_number_outlined,
                        validator: Validators.vehiclePlate,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _vehicleSeatsController,
                        hintText: l10n.vehicleSeats,
                        prefixIcon: Icons.event_seat_outlined,
                        keyboardType: TextInputType.number,
                        validator: Validators.seats,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppShadows.softCard(context),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textHintLight,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
