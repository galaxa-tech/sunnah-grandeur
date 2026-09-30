import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/shop/shop_cart_screen.dart';
import '../app_snackbar.dart';
import '../net_image.dart';
import 'product_card.dart' show ProductImageFallback;

/// Adds [product] to the cart and confirms it with a toast showing the
/// product thumbnail and a "View cart" action. The Store tab's badge bumps
/// at the same time (see ShellScreen), so the add is visible twice.
void addToCartWithFeedback(
  BuildContext context,
  ProductModel product, {
  String variant = 'Standard',
  int quantity = 1,
}) {
  final cart = context.read<CartProvider>();
  final lang = context.read<LanguageProvider>();
  cart.addToCart(product, variant, quantity);

  showAppSnackbar(
    context,
    '${product.name} · ${lang.tr('added_to_cart')}',
    type: AppSnackbarType.success,
    duration: const Duration(milliseconds: 2600),
    leading: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: 36,
        child: product.primaryImage.isEmpty
            ? ProductImageFallback(categoryId: product.categoryId)
            : NetImage(product.primaryImage,
                fallback: ProductImageFallback(categoryId: product.categoryId)),
      ),
    ),
    actionLabel: lang.tr('view_cart'),
    onAction: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopCartScreen()),
    ),
  );
}
