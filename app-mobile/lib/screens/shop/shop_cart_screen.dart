import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/language_provider.dart';
import '../store/checkout_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/net_image.dart';
import '../../widgets/shop/product_card.dart' show ProductImageFallback;

// ─────────────────────────────────────────────────────────────────────────────
// ShopCartScreen
//
// Removing is always recoverable: swipe or the labelled "Remove" button
// deletes one line with an Undo toast; "−" at quantity 1 asks first; "Clear
// cart" lives in the app bar behind a confirmation dialog. Totals use the
// same shipping/tax rules the server charges.
// ─────────────────────────────────────────────────────────────────────────────
class ShopCartScreen extends StatelessWidget {
  const ShopCartScreen({super.key});

  Future<void> _remove(BuildContext context, CartItem item) async {
    final cart = context.read<CartProvider>();
    final lang = context.read<LanguageProvider>();
    HapticFeedback.mediumImpact();
    final snapshot = CartItem(
        product: item.product, variant: item.variant, quantity: item.quantity);
    await cart.removeFromCart(item);
    if (!context.mounted) return;
    showAppSnackbar(
      context,
      '${item.product.name} · ${lang.tr('removed_from_cart')}',
      actionLabel: lang.tr('undo'),
      onAction: () => cart.restoreItem(snapshot),
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _decrement(BuildContext context, CartItem item) async {
    if (item.quantity > 1) {
      HapticFeedback.selectionClick();
      context.read<CartProvider>().updateQuantity(item, item.quantity - 1);
      return;
    }
    final lang = context.read<LanguageProvider>();
    final ok = await _confirm(
      context,
      title: lang.tr('remove_item_q'),
      body: item.product.name,
      confirmLabel: lang.tr('remove'),
    );
    if (ok && context.mounted) _remove(context, item);
  }

  Future<void> _clearAll(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final ok = await _confirm(
      context,
      title: lang.tr('clear_cart_q'),
      body: lang.tr('clear_cart_body'),
      confirmLabel: lang.tr('clear_cart'),
    );
    if (ok && context.mounted) {
      HapticFeedback.heavyImpact();
      context.read<CartProvider>().clearCart();
    }
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final c = AppColors.of(context);
    final lang = context.read<LanguageProvider>();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.elev,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.w700, color: c.t1)),
        content: Text(body, style: GoogleFonts.manrope(fontSize: 14, color: c.t2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.tr('cancel'), style: GoogleFonts.manrope(color: c.t2)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final cart = context.watch<CartProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.t2, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cart.items.isEmpty
              ? lang.tr('your_cart')
              : '${lang.tr('your_cart')} (${cart.itemCount})',
          style: GoogleFonts.notoSerif(fontSize: 19, fontWeight: FontWeight.w700, color: c.t1),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _clearAll(context),
              icon: Icon(Icons.delete_sweep_outlined, color: c.red, size: 20),
              label: Text(lang.tr('clear_cart'),
                  style: GoogleFonts.manrope(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: c.red)),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: cart.items.isEmpty
          ? _EmptyCart(lang: lang)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _FreeShippingMeter(cart: cart, lang: lang),
                const SizedBox(height: 12),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(item.key),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _remove(context, item),
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: c.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 26),
                        ),
                        child: _CartLine(
                          item: item,
                          lang: lang,
                          onRemove: () => _remove(context, item),
                          onMinus: () => _decrement(context, item),
                          onPlus: () {
                            HapticFeedback.selectionClick();
                            cart.updateQuantity(item, item.quantity + 1);
                          },
                        ),
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(lang.tr('swipe_to_remove_hint'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 11, color: c.t3)),
                ),
              ],
            ),
      bottomNavigationBar:
          cart.items.isEmpty ? null : _SummaryBar(cart: cart, lang: lang),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.lang,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });
  final CartItem item;
  final LanguageProvider lang;
  final VoidCallback onRemove, onMinus, onPlus;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = item.product;
    final fallback = ProductImageFallback(categoryId: p.categoryId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 86,
            height: 86,
            child: p.primaryImage.isEmpty
                ? fallback
                : NetImage(p.primaryImage, fallback: fallback),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSerif(
                    fontSize: 14, fontWeight: FontWeight.w600, color: c.t1, height: 1.25)),
            const SizedBox(height: 2),
            Text('${p.category} · ${p.priceDisplay}',
                style: GoogleFonts.manrope(fontSize: 11.5, color: c.t2)),
            const SizedBox(height: 10),
            Row(children: [
              _Stepper(qty: item.quantity, onMinus: onMinus, onPlus: onPlus),
              const Spacer(),
              Text('\$${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(
                      fontSize: 16, fontWeight: FontWeight.w800, color: c.gold)),
            ]),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onRemove,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline_rounded, size: 16, color: c.red),
                const SizedBox(width: 4),
                Text(lang.tr('remove'),
                    style: GoogleFonts.manrope(
                        fontSize: 12, fontWeight: FontWeight.w700, color: c.red)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.qty, required this.onMinus, required this.onPlus});
  final int qty;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 38, height: 36, child: Icon(icon, size: 18, color: c.t1)),
        );
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.bd2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(qty > 1 ? Icons.remove_rounded : Icons.delete_outline_rounded, onMinus),
        SizedBox(
          width: 30,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: Text('$qty',
                key: ValueKey(qty),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: c.t1)),
          ),
        ),
        btn(Icons.add_rounded, onPlus),
      ]),
    );
  }
}

class _FreeShippingMeter extends StatelessWidget {
  const _FreeShippingMeter({required this.cart, required this.lang});
  final CartProvider cart;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final remaining = cart.amountToFreeShipping;
    final progress = (cart.subtotal / CartProvider.freeShippingThreshold).clamp(0.0, 1.0);
    final done = remaining <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: done ? c.green.withValues(alpha: 0.10) : c.goldSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: (done ? c.green : c.gold).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.local_shipping_outlined, size: 18, color: done ? c.green : c.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              done
                  ? lang.tr('free_shipping_unlocked')
                  : lang.tr('add_more_for_free_shipping')
                      .replaceAll('{amount}', '\$${remaining.toStringAsFixed(2)}'),
              style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.t1),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 500),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 5,
              backgroundColor: c.bd,
              valueColor: AlwaysStoppedAnimation(done ? c.green : c.gold),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.cart, required this.lang});
  final CartProvider cart;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Same settings/app_config.taxRateBps createOrder charges server-side.
    final taxRate = context.watch<StoreProvider>().taxRate;
    final tax = cart.subtotal * taxRate;
    final total = cart.subtotal + tax + cart.shipping;

    Widget row(String l, String v, {Color? vc}) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Text(l, style: GoogleFonts.manrope(fontSize: 12.5, color: c.t2)),
            const Spacer(),
            Text(v, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: vc ?? c.t1)),
          ]),
        );

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: c.bg2,
        border: Border(top: BorderSide(color: c.bd)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        row(lang.tr('subtotal'), '\$${cart.subtotal.toStringAsFixed(2)}'),
        if (taxRate > 0) row(lang.tr('estimated_tax'), '\$${tax.toStringAsFixed(2)}'),
        row(
          lang.tr('shipping'),
          cart.shipping == 0 ? lang.tr('free') : '\$${cart.shipping.toStringAsFixed(2)}',
          vc: cart.shipping == 0 ? c.green : null,
        ),
        const SizedBox(height: 8),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang.tr('total'), style: GoogleFonts.manrope(fontSize: 12, color: c.t2)),
            Text('\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.notoSerif(fontSize: 22, fontWeight: FontWeight.w700, color: c.gold)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: c.gold,
                  foregroundColor: const Color(0xFF1A1200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: Text(lang.tr('proceed_checkout'),
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.lang});
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.goldSurface),
            child: Icon(Icons.shopping_bag_outlined, size: 44, color: c.gold),
          ),
          const SizedBox(height: 20),
          Text(lang.tr('cart_empty_title'),
              style: GoogleFonts.notoSerif(fontSize: 21, fontWeight: FontWeight.w700, color: c.t1)),
          const SizedBox(height: 8),
          Text(lang.tr('cart_empty_sub'),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 14, color: c.t2)),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.gold,
              foregroundColor: const Color(0xFF1A1200),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(lang.tr('continue_shopping'),
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }
}
