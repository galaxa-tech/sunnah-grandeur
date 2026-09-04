import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;

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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
                   GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.bd2),
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rate the App', style: AppTextStyles.heading(c, fontSize: 19)),
                        Text('SPREAD THE KHAIR', style: AppTextStyles.brandTag(c)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Star icon header
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                      ),
                      child: Icon(Icons.star_outline_rounded, color: c.gold, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('Enjoying the App?', style: AppTextStyles.displayMd(c).copyWith(fontSize: 26)),
                    const SizedBox(height: 10),
                    Text(
                      'Your rating helps other Muslims discover Sunnah Grandeur. It takes just 10 seconds.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted(c, size: 13).copyWith(height: 1.65),
                    ),
                    const SizedBox(height: 28),

                    // Rating stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isFilled = index < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                              color: isFilled ? c.gold : c.gold.withValues(alpha: 0.4),
                              size: 44,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Review field
                    Container(
                      constraints: const BoxConstraints(minHeight: 100),
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.bd2),
                      ),
                      child: Text('What do you love most about Sunnah Grandeur? (optional)', style: AppTextStyles.bodyMuted(c, size: 12).copyWith(height: 1.6)),
                    ),
                    const SizedBox(height: 14),

                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: c.goldGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.thumb_up_rounded, color: c.bg, size: 18),
                          const SizedBox(width: 8),
                          Text('Rate on App Store', style: AppTextStyles.button(c).copyWith(color: const Color(0xFF0D0D0F))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Already rated? JazakAllah Khair 🤍', style: AppTextStyles.bodyMuted(c, size: 12)),
                    const SizedBox(height: 20),
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
