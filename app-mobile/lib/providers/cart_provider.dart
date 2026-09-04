import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/functions/order_service.dart';

class CartItem {
  final ProductModel product;
  final String variant;
  int quantity;

  CartItem({required this.product, required this.variant, this.quantity = 1});

  String get key => '${product.id}__$variant';
  double get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<CartItem> _items = [];

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartSub;
  bool _syncingRemote = false;

  CartProvider() {
    _authSub = _auth.authStateChanges().listen(_listenCart);
  }

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (acc, item) => acc + item.quantity);
  double get subtotal => _items.fold(0.0, (acc, item) => acc + item.totalPrice);
  double get shipping => subtotal > 0 ? 10.0 : 0.0;
  double get total => subtotal + shipping;

  Future<void> addToCart(ProductModel product, String variant, int quantity) async {
    if (quantity <= 0) return;
    final existing = _items.indexWhere((i) => i.product.id == product.id && i.variant == variant);
    final nextQty = existing >= 0 ? _items[existing].quantity + quantity : quantity;
    if (existing >= 0) {
      _items[existing].quantity = nextQty;
    } else {
      _items.add(CartItem(product: product, variant: variant, quantity: quantity));
    }
    notifyListeners();
    await _upsertRemote(product, variant, nextQty);
  }

  Future<void> removeFromCart(CartItem item) async {
    _items.removeWhere((i) => i.key == item.key);
    notifyListeners();
    final ref = _itemRef(item.product.id, item.variant);
    if (ref != null) await ref.delete();
  }

  Future<void> updateQuantity(CartItem item, int newQty) async {
    if (newQty <= 0) {
      await removeFromCart(item);
      return;
    }
    final idx = _items.indexWhere((i) => i.key == item.key);
    if (idx >= 0) {
      _items[idx].quantity = newQty;
      notifyListeners();
      await _upsertRemote(item.product, item.variant, newQty);
    }
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    _items.clear();
    notifyListeners();
    if (user == null) return;
    final snap = await _db.collection('carts').doc(user.uid).collection('items').get();
    await Future.wait(snap.docs.map((d) => d.reference.delete()));
  }

  /// Submits an order AND clears the cart.
  /// ⚠️  Use [createOrderOnly] for the Stripe flow — cart is cleared only after
  ///    payment succeeds, not before.
  Future<String?> submitOrder(String shippingMethod, {ShippingInput? shippingAddress}) async {
    if (_items.isEmpty) return null;
    try {
      final result = await OrderService.createOrder(
        items: _items.map((i) => OrderItemInput(
          productId: i.product.id,
          quantity: i.quantity,
        )).toList(),
        shipping: shippingAddress ?? ShippingInput(
          name: 'Customer',
          line1: 'Address on file',
          city: '',
          postalCode: '',
          country: 'US',
          method: shippingMethod.toLowerCase(),
        ),
      );
      await clearCart();
      return result.orderId;
    } catch (e) {
      debugPrint('[CartProvider] submitOrder: $e');
      return null;
    }
  }

  /// Creates the order server-side WITHOUT clearing the local cart.
  ///
  /// Use this for the Stripe PaymentSheet flow:
  ///   1. createOrderOnly()         → OrderResult (orderId, totalInCents, …)
  ///   2. createPaymentIntent()     → clientSecret
  ///   3. presentPaymentSheet()     → success or StripeException
  ///   4. clearCart()               → only after payment confirmed
  ///
  /// If the user cancels at step 3, the order stays in "pending" state and
  /// the cart is untouched — the user can retry or abandon safely.
  Future<OrderResult?> createOrderOnly(
    ShippingInput shipping, {
    String paymentMethod = 'card',
  }) async {
    if (_items.isEmpty) return null;
    try {
      return await OrderService.createOrder(
        items: _items.map((i) => OrderItemInput(
          productId: i.product.id,
          quantity: i.quantity,
        )).toList(),
        shipping: shipping,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      debugPrint('[CartProvider] createOrderOnly: $e');
      return null;
    }
  }

  void _listenCart(User? user) {
    _cartSub?.cancel();
    if (user == null) {
      _items.clear();
      notifyListeners();
      return;
    }

    _cartSub = _db
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .listen((snap) {
      _syncingRemote = true;
      _items
        ..clear()
        ..addAll(snap.docs.map((d) => _cartItemFromMap(d.data(), d.id)));
      _syncingRemote = false;
      notifyListeners();
    }, onError: (Object e) => debugPrint('[CartProvider] cart stream: $e'));
  }

  CartItem _cartItemFromMap(Map<String, dynamic> data, String docId) {
    final productId = (data['productId'] ?? docId.split('__').first).toString();
    final images = <String>[
      if ((data['image'] ?? '').toString().isNotEmpty) data['image'].toString(),
    ];
    return CartItem(
      product: ProductModel(
        id: productId,
        name: (data['name'] ?? '').toString(),
        category: (data['category'] ?? '').toString(),
        description: (data['description'] ?? '').toString(),
        priceInCents: ((data['priceInCents'] ?? 0) as num).toInt(),
        images: images,
        sku: (data['sku'] ?? '').toString(),
        stockQuantity: ((data['stockQuantity'] ?? 999) as num).toInt(),
        isActive: true,
        categoryId: (data['categoryId'] ?? '').toString(),
      ),
      variant: (data['variant'] ?? 'Standard').toString(),
      quantity: ((data['quantity'] ?? 1) as num).toInt(),
    );
  }

  Future<void> _upsertRemote(ProductModel product, String variant, int quantity) async {
    if (_syncingRemote) return;
    final ref = _itemRef(product.id, variant);
    if (ref == null) return;
    await ref.set({
      'productId': product.id,
      'name': product.name,
      'category': product.category,
      'categoryId': product.categoryId,
      'description': product.description,
      'priceInCents': product.priceInCents,
      'image': product.primaryImage,
      'sku': product.sku,
      'stockQuantity': product.stockQuantity,
      'variant': variant,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>>? _itemRef(String productId, String variant) {
    final user = _auth.currentUser;
    if (user == null) return null;
    final safeVariant = variant.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    return _db.collection('carts').doc(user.uid).collection('items').doc('${productId}__$safeVariant');
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
