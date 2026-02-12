import 'package:chapasdk/chapasdk.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

enum ChapaPaymentResult { success, cancelled, failed }

class ChapaPaymentResponse {
  final ChapaPaymentResult result;
  final String? txRef;
  final String? message;
  final String? paidAmount;

  const ChapaPaymentResponse({
    required this.result,
    this.txRef,
    this.message,
    this.paidAmount,
  });
}

class ChapaService {
  static const _uuid = Uuid();

  String generateTxRef() => 'ridelink-${_uuid.v4().substring(0, 8)}';

  Future<ChapaPaymentResponse> initiatePayment({
    required BuildContext context,
    required String amount,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String title,
    required String description,
    String? txRef,
  }) async {
    final ref = txRef ?? generateTxRef();

    ChapaPaymentResponse? response;

    Chapa.paymentParameters(
      context: context,
      publicKey: AppConstants.chapaPublicKey,
      currency: 'ETB',
      amount: amount,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      txRef: ref,
      title: title,
      desc: description,
      nativeCheckout: true,
      namedRouteFallBack: '',
      showPaymentMethodsOnGridView: true,
      availablePaymentMethods: const ['mpesa', 'cbebirr', 'telebirr', 'ebirr'],
      onPaymentFinished: (message, reference, paidAmount) {
        ChapaPaymentResult result;
        if (message == 'paymentSuccessful') {
          result = ChapaPaymentResult.success;
        } else if (message == 'paymentCancelled') {
          result = ChapaPaymentResult.cancelled;
        } else {
          result = ChapaPaymentResult.failed;
        }

        response = ChapaPaymentResponse(
          result: result,
          txRef: reference,
          message: message,
          paidAmount: paidAmount,
        );

        Navigator.of(context).pop();
      },
    );

    // Since Chapa SDK handles its own navigation, return a pending response.
    // The actual result is handled via the callback.
    return response ??
        ChapaPaymentResponse(
          result: ChapaPaymentResult.cancelled,
          txRef: ref,
          message: 'Payment flow started',
        );
  }
}
