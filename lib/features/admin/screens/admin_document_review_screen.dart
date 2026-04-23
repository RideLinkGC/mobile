import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class AdminDocumentReviewScreen extends StatefulWidget {
  const AdminDocumentReviewScreen({super.key});

  @override
  State<AdminDocumentReviewScreen> createState() =>
      _AdminDocumentReviewScreenState();
}

class _AdminDocumentReviewScreenState extends State<AdminDocumentReviewScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final response = await api.get(ApiEndpoints.adminDocuments);
      final list = (response.data as List? ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      if (!mounted) return;
      setState(() => _documents = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review({
    required String documentId,
    required bool approve,
  }) async {
    final api = context.read<ApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    String? rejectionReason;
    if (!approve) {
      final reasonCtrl = TextEditingController();
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejection reason'),
          content: TextField(
            controller: reasonCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Explain why this document is rejected',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      rejectionReason = reasonCtrl.text.trim();
      if (rejectionReason.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Rejection reason is required.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      await api.post(
        ApiEndpoints.verifyDocument(documentId),
        data: {
          'action': approve ? 'approve' : 'reject',
          if (!approve) 'rejectionReason': rejectionReason,
        },
      );
      await _loadDocuments();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Document Review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _documents.isEmpty
                  ? const Center(child: Text('No pending documents.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        final user = doc['user'] as Map<String, dynamic>?;
                        final documentId = doc['id']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${doc['type'] ?? 'Document'} - ${doc['status'] ?? 'PENDING'}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${user?['name'] ?? 'Unknown user'} (${user?['email'] ?? '-'})',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        text: 'Approve',
                                        isLoading: _submitting,
                                        onPressed: () => _review(
                                          documentId: documentId,
                                          approve: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppButton(
                                        text: 'Reject',
                                        isOutlined: true,
                                        onPressed: _submitting
                                            ? null
                                            : () => _review(
                                                  documentId: documentId,
                                                  approve: false,
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
