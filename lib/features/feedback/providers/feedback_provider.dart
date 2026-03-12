import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class FeedbackProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  bool get submitting => _submitting;
  bool get submitted => _submitted;
  String? get error => _error;

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

  void reset() {
    _submitting = false;
    _submitted = false;
    _error = null;
    notifyListeners();
  }
}
