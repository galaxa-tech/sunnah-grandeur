import 'functions_client.dart';

/// Stripe payment flow — all calls are server-side.
/// The client never touches the Stripe secret key or sees the raw amount.
///
/// Flow:
///   1. createOrder()           → orderId
///   2. createPaymentIntent()   → clientSecret
///   3. Present Payment Sheet   (flutter_stripe handles UI)
///   4. verifyPayment()         → confirm paid status (webhook fallback)
class PaymentService {
  /// Creates a Stripe PaymentIntent for the given order.
  /// Amount is read from Firestore server-side — client cannot influence it.
  static Future<PaymentIntentResult> createPaymentIntent(String orderId) async {
    final data = await FunctionsClient.call('createPaymentIntent', {
      'orderId': orderId,
    });
    return PaymentIntentResult.fromMap(data);
  }

  /// Fallback verification if the Stripe webhook hasn't fired yet.
  static Future<PaymentStatus> verifyPayment(String paymentIntentId) async {
    final data = await FunctionsClient.call('verifyPayment', {
      'paymentIntentId': paymentIntentId,
    });
    return PaymentStatus.fromMap(data);
  }
}

// ── Value objects ─────────────────────────────────────────────────────────────

class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final int    amountInCents;

  const PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amountInCents,
  });

  factory PaymentIntentResult.fromMap(Map<String, dynamic> m) =>
      PaymentIntentResult(
        clientSecret:    m['clientSecret']    as String,
        paymentIntentId: m['paymentIntentId'] as String,
        amountInCents:   m['amountInCents']   as int,
      );
}

class PaymentStatus {
  final String paymentIntentId;
  final String status;
  final bool   paid;

  const PaymentStatus({
    required this.paymentIntentId,
    required this.status,
    required this.paid,
  });

  factory PaymentStatus.fromMap(Map<String, dynamic> m) => PaymentStatus(
    paymentIntentId: m['paymentIntentId'] as String,
    status:          m['status']          as String,
    paid:            m['paid']            as bool,
  );
}
