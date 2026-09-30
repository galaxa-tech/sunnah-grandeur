import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

/// BrandLockup — the one "Daily Muslim · by Sunnah Grandeur" identity block.
///
/// Logo + "Daily Muslim" wordmark + small "by Sunnah Grandeur" sub-brand.
/// Used on every auth / onboarding surface so the app never shows a generic
/// icon or the old app name.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.logoSize = 96,
    this.wordmarkSize = 30,
    this.showSubBrand = true,
    this.glow = true,
  });

  final double logoSize;
  final double wordmarkSize;
  final bool showSubBrand;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: glow
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.gold.withValues(alpha: c.isDark ? 0.28 : 0.18),
                      blurRadius: logoSize * 0.45,
                      spreadRadius: -logoSize * 0.08,
                    ),
                  ],
                )
              : null,
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        SizedBox(height: logoSize * 0.14),
        ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [c.gold2, c.gold, c.gold3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(b),
          child: Text(
            lang.tr('app_name'),
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: wordmarkSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ),
        if (showSubBrand) ...[
          const SizedBox(height: 4),
          Text(
            lang.tr('by_sunnah_grandeur').toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              color: c.t3,
            ),
          ),
        ],
      ],
    );
  }
}
