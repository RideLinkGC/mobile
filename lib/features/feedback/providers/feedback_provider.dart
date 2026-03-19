import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class FeedbackItem {
  final String id;
  final String type;
  final String fromUserId;
  final String? fromUserName;
  final int? rating;
  final String? comment;
  final DateTime? createdAt;

  const FeedbackItem({
    required this.id,
    required this.type,
    required this.fromUserId,
    this.fromUserName,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final fromUser = json['fromUser'] as Map<String, dynamic>?;
    return FeedbackItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      fromUserId: json['fromUserId'] as String? ?? '',
      fromUserName: fromUser?['name'] as String?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class FeedbackProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  List<FeedbackItem> _feedbackList = [];
  bool _loadingFeedback = false;

  bool get submitting => _submitting;
  bool get submitted => _submitted;
  String? get error => _error;
  List<FeedbackItem> get feedbackList => _feedbackList;
  bool get loadingFeedback => _loadingFeedback;

  List<FeedbackItem> get ratings =>
      _feedbackList.where((f) => f.type == 'rating').toList();

  FeedbackProvider(this._apiClient);

  Future<bool> submitRating({
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required int rating,
    String? comment,
  }) async {
    _submitting = true;
    _error = null;
    _submitted = false;
    notifyListeners();

    try {
      await _apiClient.post(ApiEndpoints.feedback, data: {
        'type': 'rating',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'tripId': tripId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      _submitting = false;
      _submitted = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to submit rating: $e');
      _error = 'Failed to submit rating';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReport({
    required String fromUserId,
    required String toUserId,
    String? tripId,
    required String comment,
  }) async {
    _submitting = true;
    _error = null;
    _submitted = false;
    notifyListeners();

    try {
      await _apiClient.post(ApiEndpoints.feedback, data: {
        'type': 'report',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        if (tripId != null) 'tripId': tripId,
        'comment': comment,
      });
      _submitting = false;
      _submitted = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to submit report: $e');
      _error = 'Failed to submit report';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadFeedbackForUser(String userId) async {
    _loadingFeedback = true;
    notifyListeners();

    try {
      final response =
          await _apiClient.get(ApiEndpoints.feedbackForUser(userId));
      final list = response.data as List?;
      if (list != null) {
        _feedbackList = list
            .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load feedback: $e');
      _feedbackList = [];
    }

    _loadingFeedback = false;
    notifyListeners();
  }

  void reset() {
    _submitting = false;
    _submitted = false;
    _error = null;
    notifyListeners();
  }
}
