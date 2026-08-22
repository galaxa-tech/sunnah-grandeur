import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/sg_pill.dart';

import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  String? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = 'Standard';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
                      child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 16),
                    ),
                  ),
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: c.surf,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.bd2),
                    ),
                    child: Icon(Icons.favorite_border_rounded, color: c.t3, size: 16),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      height: 280,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.bd),
                        image: widget.product.primaryImage.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.product.primaryImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 14, left: 14,
                            child: Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                ),
                                Container(
                                  width: 6, height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                                ),
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category and title
                          Text(widget.product.category.toUpperCase(), style: AppTextStyles.brandTag(c)),
                          const SizedBox(height: 8),
                          Text(widget.product.name, style: AppTextStyles.displayMd(c).copyWith(fontSize: 26)),
                          const SizedBox(height: 6),

                          // Ratings & Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: c.gold, size: 16),
                                  const SizedBox(width: 4),
                                  Text('5.0', style: AppTextStyles.body(c, size: 13).copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  Text('(New Release)', style: AppTextStyles.bodyMuted(c, size: 11)),
                                ],
                              ),
                              Text('\$${widget.product.price.toStringAsFixed(2)}', style: AppTextStyles.heading(c, fontSize: 24, color: c.gold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SgPill(
                            label: widget.product.stock > 0 ? 'In Stock' : 'Out of Stock', 
                            variant: widget.product.stock > 0 ? 'green' : 'red', 
                            fontSize: 9
                          ),

                          const SizedBox(height: 20),
                          Container(height: 1, color: c.bd),
                          const SizedBox(height: 20),

                          // Description
                          Text('DESCRIPTION', style: AppTextStyles.brandTag(c)),
                          const SizedBox(height: 10),
                          Text(
                            widget.product.description,
                            style: AppTextStyles.bodyMuted(c, size: 12.5).copyWith(height: 1.6),
                          ),

                          const SizedBox(height: 20),

                          // Variants
                          Text('VARIANT', style: AppTextStyles.brandTag(c)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const ['Standard', '30ml', '50ml', '100ml'].map((v) => GestureDetector(
                              onTap: () => setState(() => _selectedVariant = v),
                              child: _VariantPill(label: v, isActive: _selectedVariant == v, c: c),
                            )).toList(),
                          ),

                          const SizedBox(height: 20),
                          
                          // Quantity & Add to Cart
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: c.surf,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.bd),
                            ),
                            child: Row(
                              children: [
                                // Qty control
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: c.bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: c.bd2),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () { if (_qty > 1) setState(() => _qty--); },
                                        child: Icon(Icons.remove_rounded, color: c.t3, size: 16),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text('$_qty', style: AppTextStyles.heading(c, fontSize: 16)),
                                      ),
                                      GestureDetector(
                                        onTap: () { setState(() => _qty++); },
                                        child: Icon(Icons.add_rounded, color: c.gold, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Add button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (widget.product.stock <= 0) return;
                                      context.read<CartProvider>().addToCart(
                                        widget.product, 
                                        _selectedVariant ?? 'Standard', 
                                        _qty
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Added ${widget.product.name} to cart'),
                                          backgroundColor: c.gold,
                                          duration: const Duration(seconds: 1),
                                        )
                                      );
                                    },
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: widget.product.stock > 0 ? c.goldGradient : null,
                                        color: widget.product.stock > 0 ? null : c.bd,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: widget.product.stock > 0 ? [BoxShadow(color: c.gold.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 4))] : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shopping_cart_outlined, color: widget.product.stock > 0 ? c.bg : c.t3, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock', 
                                            style: AppTextStyles.button(c).copyWith(color: widget.product.stock > 0 ? const Color(0xFF0D0D0F) : c.t3)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
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

class _VariantPill extends StatelessWidget {
  const _VariantPill({required this.label, required this.isActive, required this.c});
  final String label;
  final bool isActive;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? c.goldSurface : c.surf,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? c.gold.withOpacity(0.4) : c.bd2),
      ),
      child: Text(label, style: AppTextStyles.body(c, color: isActive ? c.gold : c.t3, size: 12).copyWith(fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
    );
  }
}
