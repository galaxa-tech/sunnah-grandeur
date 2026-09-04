// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'order_history_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderConfirmedScreen — shown after Stripe PaymentSheet succeeds.
//
// All data comes from the Cloud Function response — never from client-side cart.
// ─────────────────────────────────────────────────────────────────────────────
class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({
    super.key,
    required this.orderId,
    required this.totalDollars,
    required this.createdAt,
  });

  /// Firestore order document ID (e.g. "abc123xyz")
  final String orderId;

  /// Server-confirmed total in dollars (e.g. 85.50)
  final double totalDollars;

  /// UTC timestamp when the order was created server-side.
  final DateTime createdAt;

  // ── Derived display values ─────────────────────────────────────────────────

  String get _displayOrderId =>
      'SG-${orderId.toUpperCase().substring(0, orderId.length.clamp(0, 8))}';

  String get _displayDate {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[createdAt.month]} ${createdAt.day}, ${createdAt.year}';
  }

  String get _displayDelivery {
    // Estimate 4–7 business days after order date
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final from = createdAt.add(const Duration(days: 4));
    final to   = createdAt.add(const Duration(days: 7));
    if (from.month == to.month) {
      return '${months[from.month]} ${from.day}–${to.day}';
    }
    return '${months[from.month]} ${from.day} – ${months[to.month]} ${to.day}';
  }

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
                      // ── Success icon ──────────────────────────────────────
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.goldSurface,
                          border: Border.all(
                              color: c.gold.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.check_rounded,
                              color: c.gold, size: 50),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text('Alhamdulillah!',
                          style:
                              AppTextStyles.brand(c).copyWith(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text('Order Placed Successfully',
                          style: AppTextStyles.heading(c, fontSize: 20)),
                      const SizedBox(height: 16),

                      Text(
                        'Your order $_displayOrderId has been confirmed.\n'
                        'We\'ll send you a shipping update soon.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMuted(c, size: 14)
                            .copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 40),

                      // ── Order summary card ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.bd),
                        ),
                        child: Column(
                          children: [
                            _Row(
                              label: 'Order ID',
                              value: _displayOrderId,
                              c: c,
                              valueColor: c.t1,
                            ),
                            const SizedBox(height: 12),
                            _Row(
                              label: 'Date',
                              value: _displayDate,
                              c: c,
                            ),
                            const SizedBox(height: 12),
                            _Row(
                              label: 'Amount Paid',
                              value: '\$${totalDollars.toStringAsFixed(2)}',
                              c: c,
                              valueStyle: GoogleFonts.notoSerif(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: c.gold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Row(
                              label: 'Est. Delivery',
                              value: _displayDelivery,
                              c: c,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer actions ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen())),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: c.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: c.gold.withValues(alpha: 0.22),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Track Order',
                          style: AppTextStyles.button(c)
                              .copyWith(color: const Color(0xFF0D0D0F)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.bd),
                        ),
                        alignment: Alignment.center,
                        child: Text('Back to Store',
                            style: AppTextStyles.button(c)),
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

// ─────────────────────────────────────────────────────────────────────────────
// _Row — summary row with optional custom value style
// ─────────────────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.c,
    this.valueColor,
    this.valueStyle,
  });

  final String    label;
  final String    value;
  final AppColors c;
  final Color?    valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMuted(c, size: 12)),
        valueStyle != null
            ? Text(value, style: valueStyle)
            : Text(value,
                style: AppTextStyles.body(c, size: 12).copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }
}
