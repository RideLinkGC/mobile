import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../driver/trip/providers/trip_provider.dart';
import '../providers/feedback_provider.dart';

class RatingScreen extends StatefulWidget {
  final String tripId;

  const RatingScreen({super.key, required this.tripId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _showThankYou = false;
  String? _toUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trip = await context.read<TripProvider>().getTripById(widget.tripId);
      if (mounted && trip != null) {
        setState(() => _toUserId = trip.driverId);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating < 1 || _toUserId == null) return;

    final feedbackProvider = context.read<FeedbackProvider>();
    final authProvider = context.read<AuthProvider>();
    final fromUserId = authProvider.user?.id ?? '';

    final success = await feedbackProvider.submitRating(
      tripId: widget.tripId,
      fromUserId: fromUserId,
      toUserId: _toUserId!,
      rating: _rating.round(),
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _showThankYou = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackProvider.error ?? 'Failed to submit rating'),
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
        title: Text(l10n.rating),
      ),
      body: _showThankYou
          ? _buildThankYouDialog(context)
          : _buildRatingForm(context, l10n, feedbackProvider),
    );
  }

  Widget _buildRatingForm(
      BuildContext context, AppLocalizations l10n, FeedbackProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.rateYourTrip,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 48,
              unratedColor: Colors.grey.shade300,
              itemBuilder: (context, _) => const Icon(
                Icons.star_rounded,
                color: AppColors.ratingStar,
              ),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _commentController,
            hintText: l10n.leaveComment,
            maxLines: 4,
          ),
          const SizedBox(height: 32),
          AppButton(
            text: l10n.submitRating,
            onPressed: provider.submitting ? null : _submitRating,
            isLoading: provider.submitting,
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouDialog(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thumb_up, size: 80, color: AppColors.success),
            const SizedBox(height: 24),
            Text(
              'Thank You!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your feedback helps us improve.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Done',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
