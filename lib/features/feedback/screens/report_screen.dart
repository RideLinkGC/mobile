import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/feedback_provider.dart';

class ReportScreen extends StatefulWidget {
  final String targetId;

  const ReportScreen({super.key, required this.targetId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();

  static const List<String> _categories = [
    'Safety',
    'Behavior',
    'Route deviation',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null ||
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    final feedbackProvider = context.read<FeedbackProvider>();
    final authProvider = context.read<AuthProvider>();
    final fromUserId = authProvider.user?.id ?? '';

    final comment =
        '[$_selectedCategory] ${_descriptionController.text.trim()}';

    final success = await feedbackProvider.submitReport(
      fromUserId: fromUserId,
      toUserId: widget.targetId,
      comment: comment,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. We will review it shortly.'),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackProvider.error ?? 'Failed to submit report'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedbackProvider = context.watch<FeedbackProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.report),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Issue Category',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              hint: const Text('Select category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descriptionController,
              hintText: 'Describe the issue in detail...',
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: l10n.submit,
              onPressed: feedbackProvider.submitting ? null : _submitReport,
              isLoading: feedbackProvider.submitting,
            ),
          ],
        ),
      ),
    );
  }
}
