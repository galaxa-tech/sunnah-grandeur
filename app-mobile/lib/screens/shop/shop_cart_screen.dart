// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/language_provider.dart';
import '../store/checkout_screen.dart';
import '../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShopCartScreen
// Matches: src/app/cart/page.tsx
// Layout: 8-col items + 4-col sticky summary (stacked on mobile)
// ─────────────────────────────────────────────────────────────────────────────
class ShopCartScreen extends StatelessWidget {
  const ShopCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart   = context.watch<CartProvider>();
    final lang   = context.watch<LanguageProvider>();
    final w      = MediaQuery.of(context).size.width;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.t2, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.tr('cart'),
          style: GoogleFonts.notoSerif(
            fontSize: 18, fontWeight: FontWeight.bold, color: c.t1)),
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context, lang)
          : _buildCartContent(context, cart, isWide, lang),
    );
  }

  Widget _buildEmptyCart(BuildContext context, LanguageProvider lang) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 72, color: c.bd),
          const SizedBox(height: 20),
          Text(lang.tr('cart_empty_title'),
            style: GoogleFonts.notoSerif(
              fontSize: 22, fontWeight: FontWeight.bold, color: c.t1)),
          const SizedBox(height: 8),
          Text(lang.tr('cart_empty_sub'),
            style: GoogleFonts.manrope(fontSize: 14, color: c.t2)),
          const SizedBox(height: 24),
          _GoldButton(
            label: lang.tr('continue_shopping').toUpperCase(),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
      BuildContext context, CartProvider cart, bool isWide, LanguageProvider lang) {
    final c = AppColors.of(context);
    final headerPad = isWide ? 48.0 : 20.0;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(headerPad, 24, headerPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.tr('your_cart'),
            style: GoogleFonts.notoSerif(
              fontSize: 28, fontWeight: FontWeight.bold, color: c.gold)),
          const SizedBox(height: 4),
          Text(lang.tr('cart_review_sub'),
            style: GoogleFonts.manrope(fontSize: 13, color: c.t2)),
        ],
      ),
    );

    if (isWide) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Padding(
              padding: EdgeInsets.fromLTRB(headerPad, 0, headerPad, 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _CartItemsList(cart: cart)),
                  const SizedBox(width: 32),
                  SizedBox(width: 320,
                      child: _OrderSummary(cart: cart)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: headerPad),
      child: Column(
        children: [
          header,
          _CartItemsList(cart: cart),
          const SizedBox(height: 24),
          _OrderSummary(cart: cart),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartItemsList
// ─────────────────────────────────────────────────────────────────────────────
class _CartItemsList extends StatelessWidget {
  const _CartItemsList({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: cart.items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.bd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.bd),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.product.primaryImage.isNotEmpty
                  ? Image.network(item.product.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _fallback(item.product.categoryId, c.gold))
                  : _fallback(item.product.categoryId, c.gold),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name,
                              style: GoogleFonts.manrope(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: c.t1)),
                            const SizedBox(height: 2),
                            Text(
                              '${item.product.category} / ${item.variant}',
                              style: GoogleFonts.manrope(
                                  fontSize: 12, color: c.t2)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cart.removeFromCart(item),
                        child: Icon(Icons.delete_outline_rounded,
                            color: c.t2, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Qty stepper
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: c.bd),
                          borderRadius: BorderRadius.circular(4),
                          color: c.bg,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _QtyBtn(Icons.remove_rounded,
                              () {
                                HapticFeedback.selectionClick();
                                cart.updateQuantity(
                                    item, item.quantity - 1);
                              }),
                          SizedBox(
                            width: 36,
                            child: Text('${item.quantity}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                  fontSize: 13, color: c.t1)),
                          ),
                          _QtyBtn(Icons.add_rounded,
                              () {
                                HapticFeedback.selectionClick();
                                cart.updateQuantity(
                                    item, item.quantity + 1);
                              }),
                        ]),
                      ),
                      Text('\$${item.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: c.gold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _fallback(String catId, Color gold) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: catId == 'fragrance'
              ? const [Color(0xFF1a1206), Color(0xFF2d1f08)]
              : catId == 'salah'
                  ? const [Color(0xFF1a0f1a), Color(0xFF2d1a2d)]
                  : const [Color(0xFF141414), Color(0xFF1f1f1f)],
        ),
      ),
      child: Icon(Icons.shopping_bag_outlined,
          color: gold.withValues(alpha: 0.3), size: 28),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 32, height: 36,
        child: Icon(icon, size: 14, color: AppColors.of(context).t2)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrderSummary
// ─────────────────────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    // Same settings/app_config.taxRateBps createOrder charges from
    // server-side — keeps this estimate from ever silently diverging from
    // the real charge.
    final c = AppColors.of(context);
    final taxRate = context.watch<StoreProvider>().taxRate;
    final lang  = context.watch<LanguageProvider>();
    final tax   = cart.subtotal * taxRate;
    final total = cart.subtotal + tax; // free shipping

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.bd),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.tr('order_summary'),
            style: GoogleFonts.notoSerif(
              fontSize: 20, fontWeight: FontWeight.bold, color: c.gold)),
          const SizedBox(height: 8),
          Divider(color: c.bd),
          const SizedBox(height: 16),

          _Row(lang.tr('subtotal'), '\$${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _Row('${lang.tr('estimated_tax')} (${(taxRate * 100).toStringAsFixed(1)}%)',
              '\$${tax.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.tr('shipping'),
                  style: GoogleFonts.manrope(fontSize: 13, color: c.t2)),
              Text(lang.tr('free_shipping_usa'),
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: const Color(0xFF4ade80))),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: c.bd),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(lang.tr('total'),
                  style: GoogleFonts.manrope(fontSize: 15, color: c.t1)),
              Text('\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.notoSerif(
                  fontSize: 22, fontWeight: FontWeight.bold, color: c.gold)),
            ],
          ),

          const SizedBox(height: 28),
          _GoldButton(
            label: lang.tr('proceed_checkout'),
            icon:  Icons.arrow_forward_rounded,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: c.t2, size: 14),
              const SizedBox(width: 6),
              Text(lang.tr('secure_checkout'),
                style: GoogleFonts.manrope(
                  fontSize: 10, fontWeight: FontWeight.bold,
                  color: c.t2, letterSpacing: 1.2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, color: c.t2)),
        Text(value,  style: GoogleFonts.manrope(fontSize: 13, color: c.t1)),
      ],
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
            color: c.gold, borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
              style: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: c.bg, letterSpacing: 1.5)),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: c.bg, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
