import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _nationalIdFront;
  File? _nationalIdBack;
  File? _driversLicense;
  bool _isSubmitting = false;
  bool _loadingStatus = true;
  String _verificationStatus = 'pending';
  String? _statusError;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVerificationStatus());
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });
    try {
      final api = context.read<ApiClient>();
      final response = await api.get(ApiEndpoints.verificationStatus);
      final data = response.data as Map<String, dynamic>? ?? {};
      final docs = (data['documents'] as List? ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      if (!mounted) return;
      setState(() {
        _verificationStatus = (data['status']?.toString() ?? 'pending').toLowerCase();
        _documents = docs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = 'Failed to load verification status');
    } finally {
      if (mounted) {
        setState(() => _loadingStatus = false);
      }
    }
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        switch (type) {
          case 'id_front':
            _nationalIdFront = File(image.path);
            break;
          case 'id_back':
            _nationalIdBack = File(image.path);
            break;
          case 'license':
            _driversLicense = File(image.path);
            break;
        }
      });
    }
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    if (_nationalIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the front of your National ID')),
      );
      return;
    }

    if (user.isDriver && _driversLicense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your driver's license")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Upload documents via API when endpoint is available
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
    await _loadVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDriver = user?.isDriver ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingStatus)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_statusError != null) ...[
                    Text(
                      _statusError!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verify your identity to unlock full features',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current status: ${_verificationStatus.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _verificationStatus == 'approved'
                              ? AppColors.success
                              : _verificationStatus == 'rejected'
                                  ? AppColors.error
                                  : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload clear photos of your documents. All information is securely stored and used only for verification.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            if (_documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _documents
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${d['type']}: ${d['status']}${d['rejectionReason'] != null ? ' - ${d['rejectionReason']}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('National ID (Required)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DocumentUploadCard(
                    label: 'Front',
                    file: _nationalIdFront,
                    onTap: () => _pickImage('id_front'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DocumentUploadCard(
                    label: 'Back',
                    file: _nationalIdBack,
                    onTap: () => _pickImage('id_back'),
                  ),
                ),
              ],
            ),
            if (isDriver) ...[
              const SizedBox(height: 24),
              Text("Driver's License (Required for Drivers)",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _DocumentUploadCard(
                label: "Driver's License",
                file: _driversLicense,
                onTap: () => _pickImage('license'),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              text: _verificationStatus == 'approved'
                  ? 'Verification Complete'
                  : 'Submit for Verification',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;

  const _DocumentUploadCard({
    required this.label,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: file != null
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: file != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppShadows.softCard(context),
        ),
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: AppColors.textHintLight),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
