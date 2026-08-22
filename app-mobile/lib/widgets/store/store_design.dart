import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const sgStoreBg = Color(0xFF0A0A0A);
const sgStoreSurface = Color(0xFF141414);
const sgStoreBorder = Color(0xFF1F1F1F);
const sgStoreGold = Color(0xFFC9A84C);
const sgStoreText = Color(0xFFFFFFFF);
const sgStoreMuted = Color(0xFFA0A0A0);

TextStyle sgLabel({Color color = sgStoreGold, double size = 11}) {
  return GoogleFonts.manrope(
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
  );
}

TextStyle sgSerif({Color color = sgStoreText, double size = 28}) {
  return GoogleFonts.notoSerif(
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
}

TextStyle sgBody({Color color = sgStoreMuted, double size = 12, FontWeight weight = FontWeight.w500}) {
  return GoogleFonts.manrope(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: 1.45,
  );
}

IconData storeIcon(String key) {
  switch (key) {
    case 'person':
      return Icons.person_outline;
    case 'woman':
      return Icons.woman_outlined;
    case 'child_care':
      return Icons.child_care_outlined;
    case 'mosque':
      return Icons.mosque_outlined;
    case 'menu_book':
      return Icons.menu_book_outlined;
    case 'water_drop':
      return Icons.water_drop_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'star':
    case 'crescent_moon':
      return Icons.star_border_rounded;
    case 'flight':
      return Icons.flight_takeoff_outlined;
    case 'card_giftcard':
      return Icons.card_giftcard_outlined;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'new_releases':
      return Icons.new_releases_outlined;
    default:
      return Icons.storefront_outlined;
  }
}

class StoreIconButton extends StatelessWidget {
  const StoreIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: sgStoreSurface,
              border: Border.all(color: sgStoreBorder),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: sgStoreText, size: 20),
          ),
          if ((badge ?? 0) > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17),
                height: 17,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(color: sgStoreGold, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '${badge!}',
                  style: sgBody(color: sgStoreBg, size: 9, weight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
