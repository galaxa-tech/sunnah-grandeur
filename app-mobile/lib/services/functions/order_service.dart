import 'package:cloud_firestore/cloud_firestore.dart';
import 'functions_client.dart';

/// Order creation MUST go through Cloud Functions.
/// Reads (order history) can go direct via Firestore — rules enforce userId match.
class OrderService {
  static final _db = FirebaseFirestore.instance;

  /// Creates an order server-side. Returns the new orderId and confirmed totals.
  /// Price, tax, and shipping are calculated on the server — the client sends
  /// only item quantities and shipping address.
  static Future<OrderResult> createOrder({
    required List<OrderItemInput> items,
    required ShippingInput shipping,
    String paymentMethod = 'card', // 'cod' | 'card'
  }) async {
    final data = await FunctionsClient.call('createOrder', {
      'items':         items.map((i) => i.toMap()).toList(),
      'shipping':      shipping.toMap(),
      'paymentMethod': paymentMethod,
    });
    return OrderResult.fromMap(data);
  }

  /// Streams the authenticated user's order history directly from Firestore.
  /// Firestore rules guarantee only the owner can read their orders.
  static Stream<List<OrderSummary>> watchOrders(String uid) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(OrderSummary.fromDoc).toList());
  }
}

// ── Value objects ─────────────────────────────────────────────────────────────

class OrderItemInput {
  final String productId;
  final int    quantity;

  const OrderItemInput({required this.productId, required this.quantity});

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'quantity':  quantity,
  };
}

class ShippingInput {
  final String name;
  final String phone;
  final String email;
  final String line1;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String method; // 'standard' | 'express'

  const ShippingInput({
    required this.name,
    this.phone = '',
    this.email = '',
    required this.line1,
    required this.city,
    this.state = '',
    required this.postalCode,
    required this.country,
    required this.method,
  });

  Map<String, dynamic> toMap() => {
    'name':       name,
    'phone':      phone,
    'email':      email,
    'line1':      line1,
    'city':       city,
    'state':      state,
    'postalCode': postalCode,
    'country':    country,
    'method':     method,
  };
}

class OrderResult {
  final String orderId;
  final int    subtotalInCents;
  final int    taxInCents;
  final int    shippingInCents;
  final int    totalInCents;
  final String status;

  const OrderResult({
    required this.orderId,
    required this.subtotalInCents,
    required this.taxInCents,
    required this.shippingInCents,
    required this.totalInCents,
    required this.status,
  });

  factory OrderResult.fromMap(Map<String, dynamic> m) => OrderResult(
    orderId:         m['orderId']         as String,
    subtotalInCents: m['subtotalInCents'] as int,
    taxInCents:      m['taxInCents']      as int,
    shippingInCents: m['shippingInCents'] as int,
    totalInCents:    m['totalInCents']    as int,
    status:          m['status']          as String,
  );

  /// Human-readable dollar amount from server-confirmed cents.
  double get totalDollars => totalInCents / 100;
}

class OrderSummary {
  final String   id;
  final String   status;
  final int      totalInCents;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalInCents,
    required this.createdAt,
  });

  factory OrderSummary.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return OrderSummary(
      id:           doc.id,
      status:       d['status']       as String? ?? 'unknown',
      totalInCents: d['totalInCents'] as int?    ?? 0,
      createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get totalDollars => totalInCents / 100;
}
