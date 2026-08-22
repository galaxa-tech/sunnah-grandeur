import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/store/store_design.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isEmpty = cart.items.isEmpty;

    return Scaffold(
      backgroundColor: sgStoreBg,
      body: SafeArea(
        child: Column(
          children: [
            _CartNav(onClear: isEmpty ? null : () { cart.clearCart(); }),
            Expanded(child: isEmpty ? const _EmptyCart() : _CartList(cart: cart)),
            if (!isEmpty) _CartSummary(cart: cart),
          ],
        ),
      ),
    );
  }
}

class _CartNav extends StatelessWidget {
  const _CartNav({required this.onClear});
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: sgStoreBorder))),
      child: Row(
        children: [
          StoreIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(child: Text('Your Cart', style: sgBody(color: sgStoreText, size: 15, weight: FontWeight.w900))),
          StoreIconButton(icon: Icons.delete_outline_rounded, onTap: onClear),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: sgStoreSurface,
                border: Border.all(color: sgStoreBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: sgStoreGold, size: 38),
            ),
            const SizedBox(height: 20),
            Text('Your cart is empty', style: sgSerif(size: 24)),
            const SizedBox(height: 8),
            Text('Discover sunnah-inspired products for your daily life.', textAlign: TextAlign.center, style: sgBody(size: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: sgStoreGold, borderRadius: BorderRadius.circular(4)),
                child: Text('START SHOPPING', style: sgBody(color: sgStoreBg, size: 12, weight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: sgStoreSurface,
            border: Border.all(color: sgStoreBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 96,
                decoration: BoxDecoration(
                  color: sgStoreBg,
                  borderRadius: BorderRadius.circular(4),
                  image: item.product.primaryImage.isEmpty
                      ? null
                      : DecorationImage(image: NetworkImage(item.product.primaryImage), fit: BoxFit.cover),
                ),
                child: item.product.primaryImage.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, color: sgStoreGold)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: sgBody(color: sgStoreText, size: 13, weight: FontWeight.w900)),
                        ),
                        GestureDetector(
                          onTap: () => cart.removeFromCart(item),
                          child: const Icon(Icons.close_rounded, color: sgStoreMuted, size: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.variant.toUpperCase(), style: sgLabel(color: sgStoreMuted, size: 8)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('\$${item.totalPrice.toStringAsFixed(2)}', style: sgBody(color: sgStoreGold, size: 15, weight: FontWeight.w900)),
                        const Spacer(),
                        Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: sgStoreBg,
                            border: Border.all(color: sgStoreBorder),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => cart.updateQuantity(item, item.quantity - 1),
                                icon: const Icon(Icons.remove_rounded, color: sgStoreMuted, size: 15),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text('${item.quantity}', style: sgBody(color: sgStoreText, size: 12, weight: FontWeight.w900)),
                              IconButton(
                                onPressed: () => cart.updateQuantity(item, item.quantity + 1),
                                icon: const Icon(Icons.add_rounded, color: sgStoreGold, size: 15),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: sgStoreSurface,
        border: Border(top: BorderSide(color: sgStoreBorder)),
      ),
      child: Column(
        children: [
          _Line(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 7),
          _Line(label: 'Shipping', value: '\$${cart.shipping.toStringAsFixed(2)}'),
          const Divider(color: sgStoreBorder, height: 22),
          _Line(label: 'Total', value: '\$${cart.total.toStringAsFixed(2)}', total: true),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final auth = context.read<AuthProvider>();
              if (auth.firebaseUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please login to checkout', style: sgBody(color: sgStoreText)), backgroundColor: sgStoreSurface),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
            },
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: sgStoreGold, borderRadius: BorderRadius.circular(4)),
              child: Text('PROCEED TO CHECKOUT', style: sgBody(color: sgStoreBg, size: 12, weight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.total = false});
  final String label;
  final String value;
  final bool total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: sgBody(size: total ? 15 : 13, color: total ? sgStoreText : sgStoreMuted, weight: total ? FontWeight.w900 : FontWeight.w600)),
        Text(value, style: sgBody(size: total ? 21 : 14, color: total ? sgStoreGold : sgStoreText, weight: FontWeight.w900)),
      ],
    );
  }
}
