import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/functions/payment_service.dart';
import 'order_confirmed_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _shippingMethod = 'Standard';
  bool _isProcessing = false;

  Future<void> _handleCompleteOrder() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Card payments are only available on the mobile app. Please download the app to complete your purchase.'),
        duration: Duration(seconds: 4),
      ));
      return;
    }

    setState(() => _isProcessing = true);
    final cart = context.read<CartProvider>();

    try {
      // 1. Create order via Cloud Function (uid from server auth, never from client)
      final orderId = await cart.submitOrder(_shippingMethod);
      if (orderId == null) throw Exception('Failed to create order — please try again.');

      // 2. Create PaymentIntent via Cloud Function
      final result = await PaymentService.createPaymentIntent(orderId);

      // 3. Initialize and present Stripe Payment Sheet (mobile only)
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: result.clientSecret,
          merchantDisplayName: 'Sunnah Grandeur',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // 4. Success
      cart.clearCart();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderConfirmedScreen()));
      }
    } catch (e) {
      debugPrint('[CheckoutScreen] order/payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is StripeException ? (e.error.localizedMessage ?? 'Payment cancelled') : 'Payment failed. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.userData;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
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
                      child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Checkout', style: AppTextStyles.heading(c, fontSize: 17)),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    _EyeRow(label: 'Delivery Details', c: c),

                    // Delivery Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.bd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(user?.name ?? 'Guest User', style: AppTextStyles.heading(c, fontSize: 15)),
                              Icon(Icons.edit_rounded, color: c.gold, size: 14),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('123 Islamic Center Way\nApt 4B\nNew York, NY 10001\nUnited States', style: AppTextStyles.bodyMuted(c, size: 12).copyWith(height: 1.5)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, color: c.t3, size: 14),
                              const SizedBox(width: 6),
                              Text(user?.phone ?? '+1 (555) 000-0000', style: AppTextStyles.bodyMuted(c, size: 12)),
                            ],
                          )
                        ],
                      ),
                    ),

                    _EyeRow(label: 'Shipping Method', c: c),

                    _MethodCard(
                      title: 'Standard Shipping',
                      sub: '5-7 business days',
                      trailing: '\$10.00',
                      isActive: _shippingMethod == 'Standard',
                      onTap: () => setState(() => _shippingMethod = 'Standard'),
                      c: c,
                    ),
                    _MethodCard(
                      title: 'Express Shipping',
                      sub: '2-3 business days',
                      trailing: '\$25.00',
                      isActive: _shippingMethod == 'Express',
                      onTap: () => setState(() => _shippingMethod = 'Express'),
                      c: c,
                    ),

                    _EyeRow(label: 'Payment Method', c: c),

                    _MethodCard(
                      title: 'Credit / Debit Card',
                      sub: 'Secure Payment via Stripe',
                      icon: Icons.credit_card_rounded,
                      isActive: true,
                      onTap: () {},
                      c: c,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Footer
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
                        Text('Total to pay', style: AppTextStyles.bodyMuted(c, size: 13)),
                        Text('\$${cart.total.toStringAsFixed(2)}', style: AppTextStyles.heading(c, fontSize: 24, color: c.gold)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (kIsWeb)
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.bd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_iphone_rounded, color: c.t3, size: 16),
                            const SizedBox(width: 8),
                            Text('Pay via Mobile App', style: AppTextStyles.button(c).copyWith(color: c.t3)),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _isProcessing ? null : _handleCompleteOrder,
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
                              if (_isProcessing)
                                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF0D0D0F), strokeWidth: 2))
                              else ...[
                                Text('Complete Order', style: AppTextStyles.button(c).copyWith(color: const Color(0xFF0D0D0F))),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF0D0D0F), size: 18),
                              ],
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
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title, required this.sub, this.trailing, this.icon,
    required this.isActive, required this.onTap, required this.c,
  });
  final String title, sub;
  final String? trailing;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? c.goldSurface : c.surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? c.gold.withOpacity(0.4) : c.bd),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: isActive ? c.gold : c.t3, size: 24),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading(c, fontSize: 14).copyWith(color: isActive ? c.gold : null)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppTextStyles.bodyMuted(c, size: 11)),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: AppTextStyles.heading(c, fontSize: 14)),
            if (trailing == null)
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? c.gold : c.bd2, width: 1.5),
                ),
                child: isActive 
                  ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle)))
                  : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.c});
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.brandTag(c)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.gold.withOpacity(0.2), Colors.transparent])))),
        ],
      ),
    );
  }
}
