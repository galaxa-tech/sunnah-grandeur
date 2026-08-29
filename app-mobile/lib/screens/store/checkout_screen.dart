// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/functions/payment_service.dart';
import '../../services/functions/order_service.dart';
import '../../widgets/auth_gate.dart';
import 'order_confirmed_screen.dart';

// ─── Colour tokens (matches shop dark theme) ──────────────────────────────────
const _bg   = Color(0xFF0A0A0A);
const _surf = Color(0xFF141414);
const _bd   = Color(0xFF1F1F1F);
const _gold = Color(0xFFC9A84C);
const _t1   = Color(0xFFFFFFFF);
const _t2   = Color(0xFFA0A0A0);
const _err  = Color(0xFFDC2626);
const _grn  = Color(0xFF4ade80);

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutScreen — full address form + Stripe payment
// Fields: Full Name, Email, Phone, Address, City, State, ZIP, Country
// ─────────────────────────────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey    = GlobalKey<FormState>();
  bool _isProcessing = false;

  // ── Contact ────────────────────────────────────────────────────────────────
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  // ── Address ────────────────────────────────────────────────────────────────
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _stateCtrl   = TextEditingController();
  final _zipCtrl     = TextEditingController();
  String _country    = 'US';

  // ── Focus nodes ────────────────────────────────────────────────────────────
  final _emailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _addressFocus = FocusNode();
  final _cityFocus    = FocusNode();
  final _stateFocus   = FocusNode();
  final _zipFocus     = FocusNode();

  static const _countries = [
    ('US', 'United States'), ('GB', 'United Kingdom'), ('CA', 'Canada'),
    ('AU', 'Australia'), ('AE', 'UAE'), ('SA', 'Saudi Arabia'),
    ('PK', 'Pakistan'), ('IN', 'India'), ('BD', 'Bangladesh'),
    ('MY', 'Malaysia'), ('NG', 'Nigeria'), ('ZA', 'South Africa'),
    ('FR', 'France'), ('DE', 'Germany'), ('TR', 'Turkey'),
    ('EG', 'Egypt'), ('JO', 'Jordan'), ('KW', 'Kuwait'), ('QA', 'Qatar'),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill from auth profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userData;
      if (user != null) {
        _nameCtrl.text  = user.name;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _cityCtrl.dispose();
    _stateCtrl.dispose(); _zipCtrl.dispose();
    _emailFocus.dispose(); _phoneFocus.dispose(); _addressFocus.dispose();
    _cityFocus.dispose(); _stateFocus.dispose(); _zipFocus.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (kIsWeb) {
      _showSnack('Card payments are only available on the mobile app.');
      return;
    }

    setState(() => _isProcessing = true);
    final cart = context.read<CartProvider>();

    try {
      // ── Step 1: Build shipping input ──────────────────────────────────────
      final shipping = ShippingInput(
        name:       _nameCtrl.text.trim(),
        line1:      _addressCtrl.text.trim(),
        city:       _cityCtrl.text.trim(),
        state:      _stateCtrl.text.trim(),
        postalCode: _zipCtrl.text.trim(),
        country:    _country,
        method:     'standard',
      );

      // ── Step 2: Create order server-side (does NOT clear cart) ────────────
      final orderResult = await cart.createOrderOnly(shipping);
      if (orderResult == null) {
        throw Exception('Could not create order. Please check your connection and try again.');
      }

      // ── Step 3: Fetch Stripe clientSecret from server ─────────────────────
      final paymentResult = await PaymentService.createPaymentIntent(orderResult.orderId);

      // ── Step 4: Initialise Stripe PaymentSheet ────────────────────────────
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentResult.clientSecret,
          merchantDisplayName:       'Sunnah Grandeur',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary:     Color(0xFFC9A84C),
              background:  Color(0xFF0A0A0A),
              componentBackground: Color(0xFF141414),
              componentBorder: Color(0xFF1F1F1F),
              primaryText: Color(0xFFFFFFFF),
              secondaryText: Color(0xFFA0A0A0),
              placeholderText: Color(0xFF606060),
              icon: Color(0xFFC9A84C),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 8,
              borderWidth: 1,
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFFC9A84C),
                  text:       Color(0xFF0A0A0A),
                  border:     Color(0xFFC9A84C),
                ),
              ),
            ),
          ),
        ),
      );

      // ── Step 5: Present PaymentSheet — user enters card details ───────────
      await Stripe.instance.presentPaymentSheet();

      // ── Step 6: Payment confirmed — clear cart and navigate ───────────────
      // The webhook will also clear the Firestore cart, but we clear the
      // local copy immediately for a snappy UX.
      await cart.clearCart();
      HapticFeedback.mediumImpact();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmedScreen(
            orderId:      orderResult.orderId,
            totalDollars: orderResult.totalDollars,
            createdAt:    DateTime.now().toUtc(),
          ),
        ),
      );
    } on StripeException catch (e) {
      // User cancelled → silent; any other Stripe error → toast.
      final msg = e.error.localizedMessage ?? '';
      if (msg.isNotEmpty && !msg.toLowerCase().contains('cancel')) {
        _showSnack(msg);
      }
      if (mounted) setState(() => _isProcessing = false);
    } catch (e) {
      debugPrint('[CheckoutScreen] error: $e');
      _showSnack('Payment failed. Please try again.');
      if (mounted) setState(() => _isProcessing = false);
    }
    // Note: we only reset _isProcessing on failure paths above.
    // On success the screen is replaced and dispose() handles cleanup.
  }

  void _showSnack(String msg, {Color bg = _err}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final w    = MediaQuery.of(context).size.width;
    final tax  = cart.subtotal * 0.05;
    final total = cart.subtotal + tax;

    return AuthGate(
      feature: 'checkout',
      icon: Icons.shopping_cart_outlined,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _t2, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Text('Secure Checkout',
                style: GoogleFonts.notoSerif(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _t1)),
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline_rounded, color: _t2, size: 16),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: w > 900
              ? _buildWide(cart, tax, total)
              : _buildNarrow(cart, tax, total),
        ),
      ),
    );
  }

  // ── Wide layout: side-by-side form + summary ───────────────────────────────
  Widget _buildWide(CartProvider cart, double tax, double total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form — left
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactSection(),
                const SizedBox(height: 32),
                _buildAddressSection(),
                const SizedBox(height: 32),
                _buildPaymentNote(),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Summary — right sticky-ish
          SizedBox(
            width: 340,
            child: _buildOrderSummary(cart, tax, total),
          ),
        ],
      ),
    );
  }

  // ── Narrow layout: stacked ─────────────────────────────────────────────────
  Widget _buildNarrow(CartProvider cart, double tax, double total) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactSection(),
                const SizedBox(height: 28),
                _buildAddressSection(),
                const SizedBox(height: 28),
                _buildPaymentNote(),
                const SizedBox(height: 28),
                _buildCartItemsInline(cart),
              ],
            ),
          ),
        ),
        _buildStickyFooter(cart, tax, total),
      ],
    );
  }

  // ── Section: Contact Information ───────────────────────────────────────────
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Contact Information'),
        const SizedBox(height: 16),
        _FormField(
          controller: _nameCtrl,
          label: 'Full Name',
          hint: 'Muhammad Abdullah',
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Full name is required';
            if (v.trim().length < 2) return 'Name must be at least 2 characters';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _FormField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          label: 'Email Address',
          hint: 'your@email.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
            if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _FormField(
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          label: 'Phone Number',
          hint: '+1 (555) 000-0000',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]'))],
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _addressFocus.requestFocus(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone number is required';
            if (v.trim().replaceAll(RegExp(r'[\s\+\-\(\)]'), '').length < 7) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ── Section: Shipping Address ──────────────────────────────────────────────
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Shipping Address'),
        const SizedBox(height: 16),
        _FormField(
          controller: _addressCtrl,
          focusNode: _addressFocus,
          label: 'Street Address',
          hint: '123 Main Street, Apt 4B',
          prefixIcon: Icons.home_outlined,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _cityFocus.requestFocus(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Address is required';
            if (v.trim().length < 5) return 'Enter a complete address';
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _FormField(
                controller: _cityCtrl,
                focusNode: _cityFocus,
                label: 'City',
                hint: 'New York',
                prefixIcon: Icons.location_city_outlined,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _stateFocus.requestFocus(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'City is required';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormField(
                controller: _stateCtrl,
                focusNode: _stateFocus,
                label: 'State',
                hint: 'NY',
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _zipFocus.requestFocus(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FormField(
                controller: _zipCtrl,
                focusNode: _zipFocus,
                label: 'ZIP / Postal Code',
                hint: '10001',
                prefixIcon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-\s]'))],
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'ZIP required';
                  if (v.trim().replaceAll(RegExp(r'[\-\s]'), '').length < 4) {
                    return 'Invalid ZIP';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CountryDropdown(
                value: _country,
                countries: _countries,
                onChanged: (val) => setState(() => _country = val ?? 'US'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Payment note ──────────────────────────────────────────────────────────
  Widget _buildPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bd),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.credit_card_rounded, color: _gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Payment via Stripe',
                  style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _t1)),
                const SizedBox(height: 2),
                Text('Your card details are encrypted and never stored on our servers.',
                  style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart items inline (mobile only) ───────────────────────────────────────
  Widget _buildCartItemsInline(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Your Items (${cart.items.length})'),
        const SizedBox(height: 12),
        ...cart.items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surf,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _bd),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _bg,
                  border: Border.all(color: _bd),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.product.primaryImage.isNotEmpty
                    ? Image.network(item.product.primaryImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.shopping_bag_outlined, color: _gold, size: 20))
                    : const Icon(Icons.shopping_bag_outlined, color: _gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name,
                      style: GoogleFonts.manrope(fontSize: 12,
                          fontWeight: FontWeight.w600, color: _t1),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Qty: ${item.quantity}',
                      style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
                  ],
                ),
              ),
              Text('\$${item.totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.bold, color: _gold)),
            ],
          ),
        )),
      ],
    );
  }

  // ── Order summary card (wide layout) ──────────────────────────────────────
  Widget _buildOrderSummary(CartProvider cart, double tax, double total) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bd),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
            style: GoogleFonts.notoSerif(
              fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
          const SizedBox(height: 8),
          const Divider(color: _bd),
          const SizedBox(height: 16),

          // Items
          ...cart.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _bg,
                    border: Border.all(color: _bd),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.product.primaryImage.isNotEmpty
                      ? Image.network(item.product.primaryImage, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined, color: _gold, size: 16))
                      : const Icon(Icons.shopping_bag_outlined, color: _gold, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name,
                        style: GoogleFonts.manrope(fontSize: 12,
                            fontWeight: FontWeight.w600, color: _t1),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('× ${item.quantity}',
                        style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
                    ],
                  ),
                ),
                Text('\$${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(fontSize: 13, color: _t1)),
              ],
            ),
          )),

          const Divider(color: _bd),
          const SizedBox(height: 12),

          _SummaryRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _SummaryRow('Estimated Tax (5%)', '\$${tax.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping',
                style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
              Text('Free — Across the USA',
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _grn)),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: _bd),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Total',
                style: GoogleFonts.manrope(fontSize: 15, color: _t1)),
              Text('\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.notoSerif(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _gold)),
            ],
          ),

          const SizedBox(height: 24),
          _buildCompleteOrderButton(total),
          const SizedBox(height: 14),
          _buildSecureBadge(),
        ],
      ),
    );
  }

  // ── Sticky footer (mobile) ─────────────────────────────────────────────────
  Widget _buildStickyFooter(CartProvider cart, double tax, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _surf,
        border: Border(top: BorderSide(color: _bd)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Subtotal + 5% Tax',
                  style: GoogleFonts.manrope(fontSize: 12, color: _t2)),
                Text('\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Free Shipping Included',
                style: GoogleFonts.manrope(fontSize: 11, color: _grn)),
            ),
            const SizedBox(height: 14),
            _buildCompleteOrderButton(total),
            const SizedBox(height: 10),
            _buildSecureBadge(),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _buildCompleteOrderButton(double total) {
    return GestureDetector(
      onTap: _isProcessing ? null : _handleCompleteOrder,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: _isProcessing ? _gold.withOpacity(0.5) : _gold,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: _isProcessing
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF0A0A0A), strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('COMPLETE ORDER',
                    style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: _bg, letterSpacing: 1.5)),
                  const SizedBox(width: 8),
                  const Icon(Icons.lock_rounded, color: _bg, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildSecureBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.security_rounded, color: _t2, size: 13),
        const SizedBox(width: 5),
        Text('256-bit SSL Encryption',
          style: GoogleFonts.manrope(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: _t2, letterSpacing: 1.0)),
        const SizedBox(width: 10),
        const Icon(Icons.verified_outlined, color: _t2, size: 13),
        const SizedBox(width: 5),
        Text('Powered by Stripe',
          style: GoogleFonts.manrope(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: _t2, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(title.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: _gold, letterSpacing: 1.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D3020), Colors.transparent])),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FormField — styled dark text field
// ─────────────────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.focusNode,
    this.prefixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.manrope(fontSize: 14, color: _t1),
      cursorColor: _gold,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.manrope(fontSize: 12, color: _t2),
        hintStyle: GoogleFonts.manrope(fontSize: 13, color: _t2.withOpacity(0.5)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _t2, size: 18)
            : null,
        filled: true,
        fillColor: _surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _bd),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _err),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _err, width: 1.5),
        ),
        errorStyle: GoogleFonts.manrope(fontSize: 11, color: _err),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountryDropdown
// ─────────────────────────────────────────────────────────────────────────────
class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.value,
    required this.countries,
    required this.onChanged,
  });

  final String value;
  final List<(String, String)> countries;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Country',
        labelStyle: GoogleFonts.manrope(fontSize: 12, color: _t2),
        filled: true,
        fillColor: _surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _bd),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surf,
          iconSize: 18,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _t2),
          style: GoogleFonts.manrope(fontSize: 13, color: _t1),
          onChanged: onChanged,
          items: countries.map((c) => DropdownMenuItem(
            value: c.$1,
            child: Text(c.$2,
              style: GoogleFonts.manrope(fontSize: 13, color: _t1)),
          )).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SummaryRow
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
      Text(value,  style: GoogleFonts.manrope(fontSize: 13, color: _t1)),
    ],
  );
}
