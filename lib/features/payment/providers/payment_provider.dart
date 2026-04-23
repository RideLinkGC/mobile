import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/chapa_service.dart';

class PaymentRecord {
  final String id;
  final String description;
  final double amount;
  final String date;
  final PaymentStatus status;
  final String? txRef;

  const PaymentRecord({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    this.txRef,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      txRef: json['txRef'] as String?,
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return PaymentStatus.completed;
      case 'pending':
        return PaymentStatus.pending;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

class PaymentProvider extends ChangeNotifier {
  final ChapaService _chapaService;
  final ApiClient _apiClient;

  List<PaymentRecord> _payments = [];
  bool _loading = false;
  bool _processing = false;
  String? _error;
  ChapaPaymentResponse? _lastPaymentResult;

  List<PaymentRecord> get payments => _payments;
  bool get loading => _loading;
  bool get processing => _processing;
  String? get error => _error;
  ChapaPaymentResponse? get lastPaymentResult => _lastPaymentResult;

  List<PaymentRecord> get completedPayments =>
      _payments.where((p) => p.status == PaymentStatus.completed).toList();

  List<PaymentRecord> get pendingPayments =>
      _payments.where((p) => p.status == PaymentStatus.pending).toList();

  PaymentProvider(this._chapaService, this._apiClient);

  Future<void> loadPaymentHistory(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.paymentsHistory(userId));
      final data = response.data;
      final items = (data is Map<String, dynamic> ? data['items'] : null) as List?;
      _payments = (items ?? const [])
          .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
      _payments = [];
    } catch (e) {
      _error = 'Failed to load payment history';
      _payments = [];
    }

    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getBookingPaymentStatus(String bookingId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.paymentStatusByBooking(bookingId));
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> verifyPayment(String txRef) async {
    try {
      await _apiClient.post(
        ApiEndpoints.paymentsVerify,
        data: {'txRef': txRef},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ChapaPaymentResponse> payForTrip({
    required BuildContext context,
    required String bookingId,
    required String amount,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    _processing = true;
    _error = null;
    notifyListeners();

    Map<String, dynamic>? checkout;
    try {
      final initResp = await _apiClient.post(
        ApiEndpoints.paymentsInitiate,
        data: {'bookingId': bookingId},
      );
      checkout = (initResp.data as Map<String, dynamic>?)?['checkout']
          as Map<String, dynamic>?;
      if (checkout == null) {
        _processing = false;
        _error = 'Failed to initiate payment';
        notifyListeners();
        return const ChapaPaymentResponse(
          result: ChapaPaymentResult.failed,
          message: 'Failed to initiate payment',
        );
      }
    } on ApiException catch (e) {
      _processing = false;
      _error = e.message;
      notifyListeners();
      return ChapaPaymentResponse(
        result: ChapaPaymentResult.failed,
        message: e.message,
      );
    }

    final txRef = checkout['txRef']?.toString() ?? _chapaService.generateTxRef();
    final checkoutAmount = checkout['amount']?.toString() ?? amount;

    final result = await _chapaService.initiatePayment(
      // ignore: use_build_context_synchronously
      context: context,
      amount: checkoutAmount,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      txRef: txRef,
      title: 'Trip Payment',
      description: 'Payment for booking $bookingId',
    );

    if (result.result == ChapaPaymentResult.success && result.txRef != null) {
      await verifyPayment(result.txRef!);
      await getBookingPaymentStatus(bookingId);
    }

    _lastPaymentResult = result;
    _processing = false;
    notifyListeners();

    return result;
  }

  Future<ChapaPaymentResponse> subscribeToTrip({
    required BuildContext context,
    required String tripId,
    required String plan,
    required String amount,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    return const ChapaPaymentResponse(
      result: ChapaPaymentResult.failed,
      message:
          'Subscriptions are not yet migrated to backend-initiated payment flow.',
    );
  }
}
