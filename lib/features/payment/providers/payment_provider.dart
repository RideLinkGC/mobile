import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/network/api_client.dart';
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

  static final _mockPayments = [
    const PaymentRecord(
      id: 'p1',
      description: 'Bole → Megenagna',
      amount: 45,
      date: '2025-02-28',
      status: PaymentStatus.completed,
      txRef: 'ridelink-abc123',
    ),
    const PaymentRecord(
      id: 'p2',
      description: 'Kazanchis → CMC',
      amount: 35,
      date: '2025-02-27',
      status: PaymentStatus.completed,
      txRef: 'ridelink-def456',
    ),
    const PaymentRecord(
      id: 'p3',
      description: 'Piassa → Bole',
      amount: 50,
      date: '2025-02-26',
      status: PaymentStatus.pending,
      txRef: 'ridelink-ghi789',
    ),
  ];

  PaymentProvider(this._chapaService, this._apiClient);

  /// No backend payment history endpoint exists yet; use mock data.
  Future<void> loadPaymentHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Keep ApiClient wired for future history endpoint.
    // (Reading it here avoids analyzer "unused_field" while keeping DI stable.)
    _apiClient.toString();

    _payments = _mockPayments;

    _loading = false;
    notifyListeners();
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

    final txRef = _chapaService.generateTxRef();

    final result = await _chapaService.initiatePayment(
      context: context,
      amount: amount,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      txRef: txRef,
      title: 'Trip Payment',
      description: 'Payment for booking $bookingId',
    );

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
    _processing = true;
    _error = null;
    notifyListeners();

    final txRef = _chapaService.generateTxRef();

    final result = await _chapaService.initiatePayment(
      context: context,
      amount: amount,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      txRef: txRef,
      title: '$plan Subscription',
      description: '$plan subscription for trip $tripId',
    );

    _lastPaymentResult = result;
    _processing = false;
    notifyListeners();

    return result;
  }
}
