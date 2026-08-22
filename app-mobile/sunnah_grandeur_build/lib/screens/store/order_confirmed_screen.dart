import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'order_history_screen.dart';

class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Confirmed Icon
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.goldSurface,
                          border: Border.all(color: c.gold.withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.check_rounded, color: c.gold, size: 50),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Alhamdulillah!', style: AppTextStyles.brand(c).copyWith(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text('Order Placed Successfully', style: AppTextStyles.heading(c, fontSize: 20)),
                      const SizedBox(height: 16),
                      Text(
                        'Your order #SG-84920 has been confirmed. We\'ll send you a shipping update soon.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMuted(c, size: 14).copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 40),

                      // Order Summary Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.bd),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Date', style: AppTextStyles.bodyMuted(c, size: 12)),
                                Text('Oct 14, 2024', style: AppTextStyles.body(c, size: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Amount Paid', style: AppTextStyles.bodyMuted(c, size: 12)),
                                Text('\$85.00', style: AppTextStyles.heading(c, fontSize: 13, color: c.gold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Est. Delivery', style: AppTextStyles.bodyMuted(c, size: 12)),
                                Text('Oct 18 - 20', style: AppTextStyles.body(c, size: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(18),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: c.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: c.gold.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text('Track Order', style: AppTextStyles.button(c).copyWith(color: const Color(0xFF0D0D0F))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.bd),
                        ),
                        alignment: Alignment.center,
                        child: Text('Back to Store', style: AppTextStyles.button(c)),
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
