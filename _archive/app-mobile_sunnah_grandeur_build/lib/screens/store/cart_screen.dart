import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();
    final isEmpty = cart.items.isEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.bd2),
                      ),
                      child: Icon(Icons.close_rounded, color: c.gold, size: 16),
                    ),
                  ),
                  Text('Your Cart', style: AppTextStyles.heading(c, fontSize: 17)),
                  GestureDetector(
                    onTap: () => cart.clearCart(),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.bd2)),
                      child: Icon(Icons.delete_outline_rounded, color: isEmpty ? c.t3 : c.red, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: isEmpty ? _buildEmptyCart(c) : _buildFilledCart(c, cart),
            ),

            if (!isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.bg2,
                  border: Border(top: BorderSide(color: c.bd, width: 1)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: AppTextStyles.bodyMuted(c, size: 13)),
                          Text('\$${cart.subtotal.toStringAsFixed(2)}', style: AppTextStyles.body(c, size: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Shipping', style: AppTextStyles.bodyMuted(c, size: 13)),
                          Text('\$10.00', style: AppTextStyles.body(c, size: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTextStyles.heading(c, fontSize: 16)),
                          Text('\$${cart.total.toStringAsFixed(2)}', style: AppTextStyles.heading(c, fontSize: 22, color: c.gold)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          final auth = context.read<AuthProvider>();
                          if (auth.firebaseUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to checkout')));
                            return;
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                        },
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: c.goldGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: c.gold.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Proceed to Checkout', style: AppTextStyles.button(c).copyWith(color: const Color(0xFF0D0D0F))),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0D0D0F), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              color: c.surf,
              shape: BoxShape.circle,
              border: Border.all(color: c.bd),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: c.gold, size: 38),
          ),
          const SizedBox(height: 20),
          Text('Your cart is empty', style: AppTextStyles.displaySm(c).copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text('Discover sunnah-inspired\nproducts for your daily life.', textAlign: TextAlign.center, style: AppTextStyles.bodyMuted(c, size: 13).copyWith(height: 1.5)),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => Navigator.pop(context), // back to store
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: c.goldSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.gold.withOpacity(0.3)),
              ),
              child: Text('Start Shopping', style: AppTextStyles.button(c).copyWith(color: c.gold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledCart(AppColors c, CartProvider cart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        children: cart.items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.bd),
            ),
            child: Row(
              children: [
                // Image
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(12),
                    image: item.product.primaryImage.isNotEmpty
                        ? DecorationImage(image: NetworkImage(item.product.primaryImage), fit: BoxFit.cover)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item.product.name, style: AppTextStyles.heading(c, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => cart.removeFromCart(item),
                            child: Icon(Icons.close_rounded, color: c.t3, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.variant, style: AppTextStyles.bodyMuted(c, size: 10.5)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$${item.product.price.toStringAsFixed(2)}', style: AppTextStyles.heading(c, fontSize: 15, color: c.gold)),
                          // Qty Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: c.bd2),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => cart.updateQuantity(item, item.quantity - 1),
                                  child: Icon(Icons.remove_rounded, color: c.t3, size: 14),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('${item.quantity}', style: AppTextStyles.body(c, size: 12)),
                                ),
                                GestureDetector(
                                  onTap: () => cart.updateQuantity(item, item.quantity + 1),
                                  child: Icon(Icons.add_rounded, color: c.gold, size: 14),
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
        }).toList(),
      ),
    );
  }
}
