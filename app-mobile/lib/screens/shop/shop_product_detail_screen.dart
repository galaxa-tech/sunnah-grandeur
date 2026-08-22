// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import 'shop_cart_screen.dart';

// ─── Website colour tokens ────────────────────────────────────────────────────
const _bg    = Color(0xFF070707);
const _surf  = Color(0xFF141414);
const _bd    = Color(0xFF1F1F1F);
const _gold  = Color(0xFFC9A84C);
const _t1    = Color(0xFFFFFFFF);
const _t2    = Color(0xFFA0A0A0);

// ─────────────────────────────────────────────────────────────────────────────
// ShopProductDetailScreen
// Matches: src/app/product/[id]/page.tsx
// Layout: 3-column on desktop (420px gallery | 1fr details | 300px buy-box)
//         Stacked on mobile
// ─────────────────────────────────────────────────────────────────────────────
class ShopProductDetailScreen extends StatefulWidget {
  const ShopProductDetailScreen({super.key, required this.product});
  final ProductModel product;

  @override
  State<ShopProductDetailScreen> createState() => _ShopProductDetailScreenState();
}

class _ShopProductDetailScreenState extends State<ShopProductDetailScreen> {
  int  _quantity   = 1;
  bool _giftWrap   = false;
  int  _activeThumb = 0;

  bool get _isSoldOut => widget.product.stockQuantity == 0;

  int get _discount {
    final orig = widget.product.originalPrice;
    if (orig == null || orig <= widget.product.price) return 0;
    return ((orig - widget.product.price) / orig * 100).round();
  }

  double get _savings {
    final orig = widget.product.originalPrice;
    if (orig == null) return 0;
    return orig - widget.product.price;
  }

  List<String> get _thumbs {
    final imgs = widget.product.images;
    if (imgs.isEmpty) return ['', '', ''];
    return [imgs.first, imgs.first, imgs.first];
  }

  @override
  Widget build(BuildContext context) {
    final cart    = context.watch<CartProvider>();
    final w       = MediaQuery.of(context).size.width;
    final isWide  = w > 900;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _t2, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: _gold),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: _gold),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ShopCartScreen())),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: 6, right: 4,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                      color: _gold, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${cart.itemCount}',
                      style: GoogleFonts.manrope(
                        fontSize: 8, fontWeight: FontWeight.bold,
                        color: _bg)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Breadcrumb ─────────────────────────────────────────────
            _Breadcrumb(product: widget.product),
            const SizedBox(height: 20),

            // ── Main grid ──────────────────────────────────────────────
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: gallery (420px)
                  SizedBox(width: 420, child: _buildGallery()),
                  const SizedBox(width: 32),
                  // CENTER: details (flex 1)
                  Expanded(child: _buildDetails()),
                  const SizedBox(width: 32),
                  // RIGHT: buy box (300px)
                  SizedBox(width: 300, child: _buildBuyBox(cart)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGallery(),
                  const SizedBox(height: 24),
                  _buildDetails(),
                  const SizedBox(height: 24),
                  _buildBuyBox(cart),
                ],
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ── LEFT: Image Gallery ─────────────────────────────────────────────────────
  Widget _buildGallery() {
    final p = widget.product;
    return Column(
      children: [
        // Main image
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: _surf,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _bd),
            ),
            clipBehavior: Clip.antiAlias,
            child: p.primaryImage.isNotEmpty
                ? Image.network(
                    _thumbs[_activeThumb].isNotEmpty
                        ? _thumbs[_activeThumb]
                        : p.primaryImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildGradientFallback(p),
                  )
                : _buildGradientFallback(p),
          ),
        ),
        const SizedBox(height: 8),

        // Thumbnails row
        Row(
          children: [
            ..._thumbs.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeThumb = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _activeThumb == e.key ? _gold : _bd,
                      width: _activeThumb == e.key ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: p.primaryImage.isNotEmpty && e.value.isNotEmpty
                      ? Image.network(e.value, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildGradientFallback(p))
                      : _buildGradientFallback(p),
                ),
              ),
            )),
            // 360° placeholder thumb
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _bd),
                color: _surf,
              ),
              alignment: Alignment.center,
              child: Text('360°\nView',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 9, color: _t2,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientFallback(ProductModel p) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _categoryGradient(p.categoryId),
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.25,
          child: Icon(_categoryIcon(p.categoryId),
              size: 64, color: _gold),
        ),
      ),
    );
  }

  // ── CENTER: Product details ─────────────────────────────────────────────────
  Widget _buildDetails() {
    final p = widget.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store link
        GestureDetector(
          child: Text('Visit the Sunnah Grandeur Store',
            style: GoogleFonts.manrope(
              fontSize: 13, color: _gold,
              decoration: TextDecoration.underline,
              decorationColor: _gold,
            )),
        ),
        const SizedBox(height: 16),

        // Product name
        Text(p.name,
          style: GoogleFonts.notoSerif(
            fontSize: 28, fontWeight: FontWeight.bold,
            color: _t1, height: 1.2,
          )),
        const SizedBox(height: 16),

        // Stars + badges
        Row(
          children: [
            ...List.generate(4, (_) => const Icon(Icons.star_rounded,
                color: _gold, size: 18)),
            const Icon(Icons.star_half_rounded, color: _gold, size: 18),
            const SizedBox(width: 6),
            Text('4.3',
              style: GoogleFonts.manrope(
                fontSize: 13, color: _gold,
                decoration: TextDecoration.underline,
                decorationColor: _gold,
              )),
            const SizedBox(width: 6),
            Text('(167,855)',
              style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
            if (!_isSoldOut) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1b4332),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("Customers' Choice",
                  style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: const Color(0xFF52b788),
                  )),
              ),
            ],
          ],
        ),
        if (!_isSoldOut) ...[
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '2K+ ',
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _t1)),
              TextSpan(text: 'bought in the past month',
                style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        const Divider(color: _bd),
        const SizedBox(height: 16),

        // Price block
        if (!_isSoldOut && p.badge != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF7f1d1d),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Limited time deal',
              style: GoogleFonts.manrope(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: Colors.white)),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (_discount > 0 && !_isSoldOut) ...[
              Text('-$_discount%',
                style: GoogleFonts.manrope(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: const Color(0xFFF87171),
                )),
              const SizedBox(width: 10),
            ],
            Text('\$${p.price.toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              style: GoogleFonts.manrope(
                fontSize: 32, fontWeight: FontWeight.bold,
                color: _t1,
              )),
          ],
        ),
        if (p.originalPrice != null && !_isSoldOut)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'List Price: ',
                  style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
                TextSpan(text: '\$${p.originalPrice!.toInt()}',
                  style: GoogleFonts.manrope(
                    fontSize: 13, color: _t2,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _t2,
                  )),
                TextSpan(text: '  You save \$${_savings.toInt()} ($_discount%)',
                  style: GoogleFonts.manrope(
                    fontSize: 13, color: const Color(0xFF4ade80))),
              ]),
            ),
          ),

        const SizedBox(height: 16),
        const Divider(color: _bd),
        const SizedBox(height: 16),

        // Description
        Text(p.description,
          style: GoogleFonts.manrope(
            fontSize: 15, color: const Color(0xFFD1C9BE),
            height: 1.6,
          )),

        const SizedBox(height: 24),

        // Delivery & Support badges
        _DeliverySection(),

        const SizedBox(height: 20),
        const Divider(color: _bd),
        const SizedBox(height: 12),

        // Product meta
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Category: ',
            style: GoogleFonts.manrope(fontSize: 13, color: _t1)),
          TextSpan(text: p.category,
            style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
        ])),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Type: ',
            style: GoogleFonts.manrope(fontSize: 13, color: _t1)),
          TextSpan(
            text: p.categoryId == 'fragrance'
                ? 'Artisanal Fragrance'
                : 'Islamic Lifestyle',
            style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
        ])),
      ],
    );
  }

  // ── RIGHT: Buy box ──────────────────────────────────────────────────────────
  Widget _buildBuyBox(CartProvider cart) {
    final p = widget.product;

    return Column(
      children: [
        // Buy box card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surf,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _bd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buy New',
                style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
              const SizedBox(height: 4),
              Text('\$${p.price.toInt()}',
                style: GoogleFonts.manrope(
                  fontSize: 26, fontWeight: FontWeight.bold,
                  color: _t1)),
              const SizedBox(height: 14),

              if (!_isSoldOut) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.local_shipping_outlined,
                      color: Color(0xFF4ade80), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'FREE ',
                          style: GoogleFonts.manrope(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: const Color(0xFF4ade80))),
                        TextSpan(text: 'shipping on every purchase',
                          style: GoogleFonts.manrope(fontSize: 13, color: _t2)),
                      ])),
                      Text('Free Delivery Across the USA',
                        style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
                    ],
                  )),
                ]),
                const SizedBox(height: 12),
              ],

              // Stock status
              Text(
                _isSoldOut ? 'Currently Unavailable' : 'In Stock',
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _isSoldOut
                      ? const Color(0xFFF87171)
                      : const Color(0xFF4ade80),
                ),
              ),
              const SizedBox(height: 14),

              // Quantity
              if (!_isSoldOut) ...[
                Row(
                  children: [
                    Text('Quantity:',
                      style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _bd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyBtn(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                          ),
                          SizedBox(
                            width: 36,
                            child: Text('$_quantity',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13, color: _t1)),
                          ),
                          _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: () {
                              if (_quantity < 5) setState(() => _quantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // CTAs
              if (_isSoldOut)
                const _FilledBtn(
                  label: 'OUT OF STOCK',
                  onTap: null,
                  disabled: true,
                )
              else
                Column(children: [
                  _FilledBtn(
                    label:  'ADD TO CART',
                    icon:   Icons.shopping_bag_outlined,
                    onTap:  () => _doAddToCart(cart),
                    gold:   true,
                  ),
                  const SizedBox(height: 8),
                  _FilledBtn(
                    label:  'BUY NOW',
                    onTap:  () => _doBuyNow(cart),
                    orange: true,
                  ),
                ]),

              const SizedBox(height: 16),
              const Divider(color: _bd),
              const SizedBox(height: 12),

              // Meta rows
              ...[
                ('Shipper / Seller', 'Sunnah Grandeur', true),
                ('Returns', '30-day refund / replacement', false),
                ('Payment', 'Secure transaction', false),
              ].map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(row.$1,
                        style: GoogleFonts.manrope(
                          fontSize: 11, color: _t2)),
                    ),
                    Expanded(
                      child: Text(row.$2,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: row.$3 ? _gold : _t1,
                          decoration: row.$3
                              ? TextDecoration.underline
                              : null,
                          decorationColor: row.$3 ? _gold : null,
                        )),
                    ),
                  ],
                ),
              )),

              if (!_isSoldOut) ...[
                const Divider(color: _bd),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _giftWrap = !_giftWrap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: _giftWrap ? _gold : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: _giftWrap ? _gold : _bd,
                            width: 1.5,
                          ),
                        ),
                        child: _giftWrap
                            ? const Icon(Icons.check_rounded,
                                size: 12, color: _bg)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: 'Add premium gift wrapping for ',
                            style: GoogleFonts.manrope(
                              fontSize: 11, color: _t2)),
                          TextSpan(text: '\$5',
                            style: GoogleFonts.manrope(
                              fontSize: 11, color: _gold)),
                        ])),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Trust badges
        Row(
          children: [
            ('local_shipping_outlined', 'Free\nShipping'),
            ('flight_land_outlined',    'USA\nDelivery'),
            ('workspace_premium',       'Premium\nQuality'),
          ].asMap().entries.map((e) {
            final icon = e.value.$1;
            final label = e.value.$2;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(left: e.key == 0 ? 0 : 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _surf,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _bd.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(_trustIcon(icon), color: _gold, size: 20),
                    const SizedBox(height: 4),
                    Text(label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 9, color: _t2, height: 1.3)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _trustIcon(String key) {
    switch (key) {
      case 'local_shipping_outlined': return Icons.local_shipping_outlined;
      case 'flight_land_outlined':    return Icons.flight_land_outlined;
      default:                        return Icons.workspace_premium_outlined;
    }
  }

  void _doAddToCart(CartProvider cart) {
    if (_isSoldOut) return;
    cart.addToCart(widget.product, 'Standard', _quantity);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _surf,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Text('${widget.product.name} added to cart',
          style: GoogleFonts.manrope(color: _t1, fontSize: 13)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _doBuyNow(CartProvider cart) {
    if (_isSoldOut) return;
    cart.addToCart(widget.product, 'Standard', _quantity);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ShopCartScreen()));
  }

  // category gradient/icon helpers
  static List<Color> _categoryGradient(String catId) {
    switch (catId) {
      case 'fragrance': return const [Color(0xFF1a1206), Color(0xFF2d1f08)];
      case 'salah':     return const [Color(0xFF1a0f1a), Color(0xFF2d1a2d)];
      case 'home':      return const [Color(0xFF0a0f1a), Color(0xFF101825)];
      case 'women':     return const [Color(0xFF0f1a0f), Color(0xFF1a2d1a)];
      case 'men':       return const [Color(0xFF1a1a1a), Color(0xFF2d2d2d)];
      default:          return const [Color(0xFF1a1206), Color(0xFF2d1f08)];
    }
  }

  static IconData _categoryIcon(String catId) {
    switch (catId) {
      case 'fragrance': return Icons.water_drop_outlined;
      case 'salah':     return Icons.mosque_outlined;
      case 'home':      return Icons.home_outlined;
      case 'women':     return Icons.woman_outlined;
      case 'men':       return Icons.person_outlined;
      default:          return Icons.shopping_bag_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _BreadCrumbItem('Home', onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
        const _BreadSep(),
        _BreadCrumbItem('Shop', onTap: () => Navigator.pop(context)),
        const _BreadSep(),
        _BreadCrumbItem(product.category),
        const _BreadSep(),
        Text(product.name,
          style: GoogleFonts.manrope(fontSize: 11, color: _gold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BreadCrumbItem extends StatelessWidget {
  const _BreadCrumbItem(this.label, {this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label,
      style: GoogleFonts.manrope(
        fontSize: 11, color: _t2,
        decoration: onTap != null ? TextDecoration.none : null,
      )),
  );
}

class _BreadSep extends StatelessWidget {
  const _BreadSep();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.chevron_right_rounded, size: 14, color: _t2);
}

class _DeliverySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_outlined,    'Free Delivery',  'Across the USA'),
      (Icons.inventory_2_outlined,       'Ships from',     'Sunnah Grandeur'),
      (Icons.assignment_return_outlined, '30-day Easy',    'Returns'),
      (Icons.support_agent_outlined,     'Customer',       'Support'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DELIVERY & SUPPORT',
          style: GoogleFonts.manrope(
            fontSize: 11, fontWeight: FontWeight.bold,
            color: _t1, letterSpacing: 2.0)),
        const SizedBox(height: 4),
        Text('Select to learn more',
          style: GoogleFonts.manrope(fontSize: 11, color: _t2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: items.map((item) => Container(
            width: 80,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surf,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _bd),
            ),
            child: Column(
              children: [
                Icon(item.$1, color: _gold, size: 22),
                const SizedBox(height: 4),
                Text(item.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 10, color: _t1,
                    fontWeight: FontWeight.w500, height: 1.3)),
                Text(item.$3,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 10, color: _t2, height: 1.3)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 32, height: 36,
      child: Icon(icon, size: 16, color: _t2),
    ),
  );
}

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({
    required this.label,
    required this.onTap,
    this.icon,
    this.gold    = false,
    this.orange  = false,
    this.disabled = false,
  });
  final String       label;
  final VoidCallback? onTap;
  final IconData?    icon;
  final bool         gold;
  final bool         orange;
  final bool         disabled;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (disabled) {
      bg = const Color(0xFF1f1f1f);
      fg = _t2;
    } else if (gold) {
      bg = _gold;
      fg = _bg;
    } else if (orange) {
      bg = const Color(0xFFf0a500);
      fg = const Color(0xFF0d0900);
    } else {
      bg = _surf;
      fg = _t1;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label,
              style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: fg, letterSpacing: 1.0,
              )),
          ],
        ),
      ),
    );
  }
}
