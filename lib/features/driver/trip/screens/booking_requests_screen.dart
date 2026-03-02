import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/rating_widget.dart';

class BookingRequestsScreen extends StatefulWidget {
  final String tripId;

  const BookingRequestsScreen({super.key, required this.tripId});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  late List<Map<String, dynamic>> _mockRequests;

  @override
  void initState() {
    super.initState();
    _mockRequests = [
      {
        'id': 'br1',
        'passengerName': 'Abebe Kebede',
        'pickup': 'Bole Atlas',
        'dropoff': 'Megenagna Square',
        'rating': 4.5,
      },
      {
        'id': 'br2',
        'passengerName': 'Sara Mohammed',
        'pickup': 'Kazanchis',
        'dropoff': 'CMC',
        'rating': 4.8,
      },
    ];
  }

  void _accept(String id) {
    setState(() => _mockRequests.removeWhere((r) => r['id'] == id));
  }

  void _decline(String id) {
    setState(() => _mockRequests.removeWhere((r) => r['id'] == id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingRequests),
      ),
      body: _mockRequests.isEmpty
          ? _buildEmptyState(l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _mockRequests.length,
              itemBuilder: (context, index) {
                final request = _mockRequests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookingRequestCard(
                    request: request,
                    l10n: l10n,
                    onAccept: () => _accept(request['id'] as String),
                    onDecline: () => _decline(request['id'] as String),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.textHintLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No booking requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Requests will appear here when passengers book this trip',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final AppLocalizations l10n;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _BookingRequestCard({
    required this.request,
    required this.l10n,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                child: Text(
                  (request['passengerName'] as String).substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['passengerName'] as String,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    AppRatingWidget(
                      rating: (request['rating'] as num).toDouble(),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.trip_origin, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request['pickup'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request['dropoff'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.accept,
                  onPressed: onAccept,
                  backgroundColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: l10n.decline,
                  onPressed: onDecline,
                  isOutlined: true,
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
