import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/store/store_design.dart';
import '../../widgets/store/store_product_card.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  int _imageIndex = 0;
  String _selectedVariant = 'Standard';

  List<String> get _variants {
    if (widget.product.volumeMl != null) return ['30ml', '50ml', '${widget.product.volumeMl!.round()}ml'];
    if (widget.product.categoryId == 'fragrance') return ['30ml', '50ml', '100ml'];
    return ['Standard'];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final isFavorite = store.isFavorite(widget.product.id);
    final related = store.allProducts
        .where((p) => p.categoryId == widget.product.categoryId && p.id != widget.product.id)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: sgStoreBg,
      body: SafeArea(
        child: Column(
          children: [
            _DetailNav(
              isFavorite: isFavorite,
              onFavorite: () => store.toggleFavorite(widget.product),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Gallery(product: widget.product, index: _imageIndex, onIndex: (v) => setState(() => _imageIndex = v)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.category.toUpperCase(), style: sgLabel()),
                        const SizedBox(height: 8),
                        Text(widget.product.name, style: sgSerif(size: 29)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(widget.product.priceDisplay, style: sgBody(color: sgStoreGold, size: 24, weight: FontWeight.w900)),
                            if (widget.product.originalPriceDisplay != null) ...[
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  widget.product.originalPriceDisplay!,
                                  style: sgBody(size: 13).copyWith(decoration: TextDecoration.lineThrough),
                                ),
                              ),
                            ],
                            const Spacer(),
                            _StockPill(stock: widget.product.stockQuantity),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: sgStoreBorder),
                        const SizedBox(height: 18),
                        Text('DESCRIPTION', style: sgLabel(color: sgStoreMuted, size: 10)),
                        const SizedBox(height: 10),
                        Text(widget.product.description, style: sgBody(size: 13).copyWith(height: 1.65)),
                        const SizedBox(height: 22),
                        Text('OPTIONS', style: sgLabel(color: sgStoreMuted, size: 10)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _variants.map((variant) {
                            final active = _selectedVariant == variant;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedVariant = variant),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? sgStoreGold.withValues(alpha: 0.15) : sgStoreSurface,
                                  border: Border.all(color: active ? sgStoreGold : sgStoreBorder),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(variant, style: sgBody(color: active ? sgStoreGold : sgStoreText, size: 12, weight: FontWeight.w900)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),
                        _AddPanel(
                          product: widget.product,
                          qty: _qty,
                          onQty: (v) => setState(() => _qty = v
                              .clamp(1, widget.product.stockQuantity < 1 ? 1 : widget.product.stockQuantity)
                              .toInt()),
                          onAdd: () => _addToCart(context),
                        ),
                        const SizedBox(height: 28),
                        _ShippingInfo(product: widget.product),
                        if (related.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          Text('RELATED PRODUCTS', style: sgLabel(color: sgStoreMuted, size: 10)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: related.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.54,
                            ),
                            itemBuilder: (context, index) {
                              final p = related[index];
                              return StoreProductCard(
                                product: p,
                                isFavorite: store.isFavorite(p.id),
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                                onAddToCart: () => context.read<CartProvider>().addToCart(p, 'Standard', 1),
                                onToggleFavorite: () => store.toggleFavorite(p),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    if (widget.product.stockQuantity <= 0) return;
    context.read<CartProvider>().addToCart(widget.product, _selectedVariant, _qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart', style: sgBody(color: sgStoreText, size: 12)),
        backgroundColor: sgStoreSurface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: sgStoreBorder)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _DetailNav extends StatelessWidget {
  const _DetailNav({required this.isFavorite, required this.onFavorite});
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: sgStoreBorder))),
      child: Row(
        children: [
          StoreIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(child: Text('Product Details', style: sgBody(color: sgStoreText, size: 15, weight: FontWeight.w900))),
          StoreIconButton(icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, onTap: onFavorite),
          const SizedBox(width: 10),
          StoreIconButton(
            icon: Icons.shopping_bag_outlined,
            badge: cartCount,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.product, required this.index, required this.onIndex});
  final ProductModel product;
  final int index;
  final ValueChanged<int> onIndex;

  @override
  Widget build(BuildContext context) {
    final images = product.images;
    final image = images.isEmpty ? '' : images[index.clamp(0, images.length - 1).toInt()];
    return Container(
      height: 390,
      color: sgStoreSurface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
          else
            Center(child: Icon(storeIcon(product.categoryId), color: sgStoreGold.withValues(alpha: 0.32), size: 96)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, sgStoreBg.withValues(alpha: 0.35)],
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 18,
              bottom: 16,
              child: Row(
                children: List.generate(images.length, (i) {
                  return GestureDetector(
                    onTap: () => onIndex(i),
                    child: Container(
                      width: i == index ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == index ? sgStoreGold : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inStock ? const Color(0xFF102A1E) : const Color(0xFF2A1010),
        border: Border.all(color: inStock ? const Color(0xFF7DD4A8) : const Color(0xFFE87D7D)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(inStock ? '$stock IN STOCK' : 'OUT OF STOCK', style: sgBody(color: inStock ? const Color(0xFF7DD4A8) : const Color(0xFFE87D7D), size: 9, weight: FontWeight.w900)),
    );
  }
}

class _AddPanel extends StatelessWidget {
  const _AddPanel({required this.product, required this.qty, required this.onQty, required this.onAdd});
  final ProductModel product;
  final int qty;
  final ValueChanged<int> onQty;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final inStock = product.stockQuantity > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sgStoreSurface,
        border: Border.all(color: sgStoreBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: sgStoreBg,
              border: Border.all(color: sgStoreBorder),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                IconButton(onPressed: () => onQty(qty - 1), icon: const Icon(Icons.remove_rounded, color: sgStoreMuted, size: 17)),
                Text('$qty', style: sgBody(color: sgStoreText, size: 14, weight: FontWeight.w900)),
                IconButton(onPressed: () => onQty(qty + 1), icon: const Icon(Icons.add_rounded, color: sgStoreGold, size: 17)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: inStock ? onAdd : null,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: inStock ? sgStoreGold : sgStoreBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(inStock ? 'ADD TO CART' : 'OUT OF STOCK', style: sgBody(color: inStock ? sgStoreBg : sgStoreMuted, size: 12, weight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingInfo extends StatelessWidget {
  const _ShippingInfo({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sgStoreSurface,
        border: Border.all(color: sgStoreBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.local_shipping_outlined, title: 'Ships from', value: 'Sunnah Grandeur'),
          const Divider(color: sgStoreBorder, height: 22),
          _InfoRow(icon: Icons.inventory_2_outlined, title: 'SKU', value: product.sku.isEmpty ? product.id : product.sku),
          const Divider(color: sgStoreBorder, height: 22),
          _InfoRow(icon: Icons.category_outlined, title: 'Type', value: product.category),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: sgStoreGold, size: 18),
        const SizedBox(width: 10),
        Text(title, style: sgBody(size: 12)),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: sgBody(color: sgStoreText, size: 12, weight: FontWeight.w800))),
      ],
    );
  }
}
