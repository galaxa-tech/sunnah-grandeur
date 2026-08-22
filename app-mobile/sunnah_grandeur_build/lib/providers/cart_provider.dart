import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/functions/order_service.dart';

class CartItem {
  final ProductModel product;
  final String variant;
  int quantity;

  CartItem({required this.product, required this.variant, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal > 0 ? subtotal + 10.0 : 0.0; // Flat $10 shipping for now

  void addToCart(ProductModel product, String variant, int quantity) {
    // Check if item exists
    final idx = _items.indexWhere((i) => i.product.id == product.id && i.variant == variant);
    if (idx >= 0) {
      _items[idx].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, variant: variant, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateQuantity(CartItem item, int newQty) {
    if (newQty <= 0) {
      removeFromCart(item);
    } else {
      final idx = _items.indexOf(item);
      if (idx >= 0) {
        _items[idx].quantity = newQty;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Submits the cart as an order via Cloud Function.
  /// [shippingAddress] is the user's delivery address from the checkout form.
  /// uid comes from the server via Firebase Auth — never passed by the client.
  Future<String?> submitOrder(String shippingMethod, {ShippingInput? shippingAddress}) async {
    if (_items.isEmpty) return null;
    try {
      final result = await OrderService.createOrder(
        items: _items.map((i) => OrderItemInput(
          productId: i.product.id,
          quantity:  i.quantity,
        )).toList(),
        shipping: shippingAddress ?? ShippingInput(
          name:       'Customer',
          line1:      'Address on file',
          city:       '',
          postalCode: '',
          country:    'GB',
          method:     shippingMethod.toLowerCase(),
        ),
      );
      return result.orderId;
    } catch (e) {
      debugPrint('[CartProvider] submitOrder: $e');
      return null;
    }
  }
}
