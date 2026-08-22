import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A product card for the Store grid.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.badge,
    this.badgeVariant = 'gold',
    this.icon,
    this.imagePath,
    this.onTap,
  });

  final String name;
  final String price;
  final String? badge;
  final String badgeVariant;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
        color: c.isDark ? c.surf : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.bd),
        boxShadow: c.isDark ? null : [
          BoxShadow(color: const Color(0x11644028),
              blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Image area
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: c.surf,
            image: imagePath != null ? DecorationImage(image: NetworkImage(imagePath!), fit: BoxFit.cover) : null,
            gradient: imagePath == null ? LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [c.gold.withOpacity(0.07), c.elev],
            ) : null,
          ),
          child: Stack(alignment: Alignment.center, children: [
            if (imagePath == null)
              Icon(icon ?? Icons.inventory_2_outlined,
                  color: c.gold.withOpacity(0.25), size: 28),
            if (badge != null)
              Positioned(
                top: 6, left: 6,
                child: _pill(c, badge!, badgeVariant),
              ),
          ]),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                style: AppTextStyles.label(c, size: 11.5),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(price, style: AppTextStyles.displaySm(c, color: c.gold)
                      .copyWith(fontSize: 17)),
                  GestureDetector(
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: c.gold.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.add, color: c.gold, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    ),
    );
  }

  Widget _pill(AppColors c, String label, String variant) {
    Color fg, bg, border;
    switch (variant) {
      case 'green': fg = c.green; bg = c.green.withOpacity(0.10); border = c.green.withOpacity(0.22); break;
      case 'red':   fg = c.red;   bg = c.red.withOpacity(0.10);   border = c.red.withOpacity(0.22);   break;
      default:      fg = c.gold;  bg = c.goldSurface;              border = c.gold.withOpacity(0.22);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 7.5, color: fg,
          fontWeight: FontWeight.w500, fontFamily: 'Jost')),
    );
  }
}
