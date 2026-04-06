import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../providers/auth_provider.dart';

class DriverSetupScreen extends StatefulWidget {
  final String licenseDocumentId;

  const DriverSetupScreen({super.key, required this.licenseDocumentId});

  @override
  State<DriverSetupScreen> createState() => _DriverSetupScreenState();
}

class _DriverSetupScreenState extends State<DriverSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleSeatsController = TextEditingController();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleSeatsController.dispose();
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
      licenseDocumentId: widget.licenseDocumentId,
    );
    if (!mounted) return;
    if (ok) {
      // Driver profile is complete; optional docs can be uploaded later in Settings.
      context.go('/driver');
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
  const DriverDocumentsScreen({super.key, this.isAfterDriverSetup = false});

  final bool isAfterDriverSetup;

  @override
  Widget build(BuildContext context) {
    // If we already completed driver setup, this page is optional.
    final auth = context.watch<AuthProvider>();
    final nextRoute = auth.isDriver ? '/driver' : '/login';
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: SafeArea(
        child: _DriverDocumentsBody(
          isAfterDriverSetup: isAfterDriverSetup,
          nextRoute: nextRoute,
        ),
      ),
    );
  }
}

class _DriverDocumentsBody extends StatefulWidget {
  const _DriverDocumentsBody({
    required this.isAfterDriverSetup,
    required this.nextRoute,
  });

  final bool isAfterDriverSetup;
  final String nextRoute;

  @override
  State<_DriverDocumentsBody> createState() => _DriverDocumentsBodyState();
}

class _DriverDocumentsBodyState extends State<_DriverDocumentsBody> {
  File? _idOrPassportFile;
  String? _licenseDocumentId;
  bool _uploadingLicense = false;
  bool _uploadingId = false;

  Future<File?> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  Future<Map<String, dynamic>> _presign({
    required String fileName,
    required String contentType,
    required String docType,
  }) async {
    final api = context.read<ApiClient>();
    try {
      final resp = await api.post(
        ApiEndpoints.presignUpload,
        data: {
          'fileName': fileName,
          'contentType': contentType,
          'docType': docType,
        },
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on NotFoundException {
      // Some deployments mount this router under `/uploads`.
      final resp = await api.post(
        '/files${ApiEndpoints.presignUpload}',
        data: {
          'fileName': fileName,
          'contentType': contentType,
          'docType': docType,
        },
      );
      return Map<String, dynamic>.from(resp.data as Map);
    }
  }

  Future<void> _completeUpload(String documentId) async {
    final api = context.read<ApiClient>();
    try {
      await api.post(
        ApiEndpoints.completeUpload,
        data: {'documentId': documentId},
      );
      return;
    } on NotFoundException {
      // Some deployments mount this router under `/uploads` or `/files`.
    }

    // Fallbacks (try common mount points)
    try {
      await api.post(
        '/uploads${ApiEndpoints.completeUpload}',
        data: {'documentId': documentId},
      );
      return;
    } catch (_) {}

    await api.post(
      '/files${ApiEndpoints.completeUpload}',
      data: {'documentId': documentId},
    );
  }

  Future<void> _uploadToPresignedUrl({
    required Uri url,
    required File file,
    required String contentType,
  }) async {
    final dio = Dio();
    final length = await file.length();
    await dio.putUri(
      url,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': length,
        },
      ),
    );
  }

  Future<void> _uploadLicense() async {
    final file = await _pickFile();
    if (file == null) return;
    if (!mounted) return;
    setState(() {
      _uploadingLicense = true;
    });

    final fileName = file.path.split('/').last;
    final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';
    try {
      // Backend docType is an enum; common values are LICENSE / NATIONAL_ID / PASSPORT.
      final presign = await _presign(
        fileName: fileName,
        contentType: contentType,
        docType: 'LICENSE',
      );
      final putUrl = Uri.parse(presign['url'] as String);
      final documentId = presign['documentId'] as String?;
      if (documentId == null || documentId.isEmpty) {
        throw Exception('Missing documentId from /upload');
      }
      await _uploadToPresignedUrl(
        url: putUrl,
        file: file,
        contentType: contentType,
      );
      await _completeUpload(documentId);
      if (!mounted) return;
      setState(() {
        _licenseDocumentId = documentId;
        _uploadingLicense = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingLicense = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('License upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadIdOrPassport(String docType) async {
    final file = await _pickFile();
    if (file == null) return;
    if (!mounted) return;
    setState(() {
      _idOrPassportFile = file;
      _uploadingId = true;
    });

    final fileName = file.path.split('/').last;
    final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';
    try {
      final presign = await _presign(
        fileName: fileName,
        contentType: contentType,
        docType: docType,
      );
      final putUrl = Uri.parse(presign['url'] as String);
      final documentId = presign['documentId'] as String?;
      if (documentId == null || documentId.isEmpty) {
        throw Exception('Missing documentId from /upload');
      }
      await _uploadToPresignedUrl(
        url: putUrl,
        file: file,
        contentType: contentType,
      );
      await _completeUpload(documentId);
      if (!mounted) return;
      setState(() => _uploadingId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _licenseDocumentId != null && !_uploadingLicense;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.isAfterDriverSetup
              ? 'Upload your documents now, or skip and do it later in Settings.'
              : 'Upload your driver’s license (required). National ID / Passport is optional.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _UploadCard(
          title: 'Driver License Document (Required)',
          subtitle: _licenseDocumentId != null
              ? 'Uploaded'
              : 'Upload image or PDF',
          icon: Icons.badge_outlined,
          isLoading: _uploadingLicense,
          onTap: _uploadingLicense ? null : _uploadLicense,
        ),
        const SizedBox(height: 12),
        _UploadCard(
          title: 'National ID / Passport (Optional)',
          subtitle: _idOrPassportFile != null ? 'Selected' : 'Upload image or PDF',
          icon: Icons.perm_identity_outlined,
          isLoading: _uploadingId,
          onTap: _uploadingId
              ? null
              : () async {
                  final choice = await showModalBottomSheet<String>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.credit_card_outlined),
                            title: const Text('National ID'),
                            onTap: () => Navigator.of(ctx).pop('NATIONAL_ID'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.book_outlined),
                            title: const Text('Passport'),
                            onTap: () => Navigator.of(ctx).pop('PASSPORT'),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (choice == null) return;
                  await _uploadIdOrPassport(choice);
                },
        ),
        const SizedBox(height: 28),
        if (widget.isAfterDriverSetup) ...[
          AppButton(
            text: 'Skip for now',
            isOutlined: true,
            onPressed: () => context.go(widget.nextRoute),
          ),
          const SizedBox(height: 10),
          AppButton(
            text: 'Continue',
            onPressed: () => context.go(widget.nextRoute),
          ),
        ] else ...[
          AppButton(
            text: 'Continue',
            onPressed: canContinue
                ? () => context.go(
                      '/register/driver-setup',
                      extra: {'licenseDocumentId': _licenseDocumentId},
                    )
                : null,
          ),
        ],
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

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
        trailing: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: onTap,
                child: const Text('Upload'),
              ),
        onTap: onTap,
      ),
    );
  }
}
