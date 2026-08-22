import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home/home_screen.dart';
import 'media/media_hub_screen.dart';
import 'shop/shop_home_screen.dart';
import 'profile/profile_screen.dart';

/// ShellScreen — persistent scaffold with a 4-tab bottom navigation bar.
/// Each tab has its own Navigator so sub-screens push within the tab.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _roots = const [
    HomeScreen(),
    MediaHubScreen(),
    ShopHomeScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, (i) => Navigator(
          key: _navigatorKeys[i],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => _roots[i],
          ),
        )),
      ),
      bottomNavigationBar: _SgBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        labels: [
          lang.tr('home'),
          lang.tr('media'),
          lang.tr('store'),
          lang.tr('profile'),
        ],
        c: c,
      ),
    );
  }
}

// ── Custom Bottom Navigation Bar ──────────────────────────────────────────────

class _SgBottomNav extends StatelessWidget {
  const _SgBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    required this.c,
  });
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> labels;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: c.bg2,
        border: Border(top: BorderSide(color: c.bd, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.30 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: [
        _NavItem(
          activeIcon:   (color) => CustomPaint(size: const Size(22, 22), painter: _HomeIconPainter(color, filled: true)),
          inactiveIcon: (color) => CustomPaint(size: const Size(22, 22), painter: _HomeIconPainter(color, filled: false)),
          label: labels[0], index: 0, currentIndex: currentIndex, onTap: () => onTap(0), c: c,
        ),
        _NavItem(
          activeIcon:   (color) => Icon(Icons.play_circle_rounded, color: color, size: 23),
          inactiveIcon: (color) => Icon(Icons.play_circle_outline_rounded, color: color, size: 23),
          label: labels[1], index: 1, currentIndex: currentIndex, onTap: () => onTap(1), c: c,
        ),
        _NavItem(
          activeIcon:   (color) => Icon(Icons.shopping_cart_rounded, color: color, size: 22),
          inactiveIcon: (color) => Icon(Icons.shopping_cart_outlined, color: color, size: 22),
          label: labels[2], index: 2, currentIndex: currentIndex, onTap: () => onTap(2), c: c,
        ),
        _NavItem(
          activeIcon:   (color) => Icon(Icons.person_rounded, color: color, size: 23),
          inactiveIcon: (color) => Icon(Icons.person_outline_rounded, color: color, size: 23),
          label: labels[3], index: 3, currentIndex: currentIndex, onTap: () => onTap(3), c: c,
        ),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.c,
  });
  final Widget Function(Color) activeIcon;
  final Widget Function(Color) inactiveIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final isOn = index == currentIndex;
    final color = isOn ? c.gold : c.t3;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 46,
              height: 30,
              decoration: BoxDecoration(
                color: isOn ? c.gold.withValues(alpha: 0.13) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isOn ? activeIcon(color) : inactiveIcon(color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.pill(c, color: color, size: 9.5).copyWith(
                fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home icon custom painter — filled or stroke ───────────────────────────────
class _HomeIconPainter extends CustomPainter {
  _HomeIconPainter(this.color, {required this.filled});
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size;

    if (filled) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Filled roof body
      final body = Path()
        ..moveTo(s.width * 3 / 22, s.height * 9.5 / 22)
        ..lineTo(s.width * 11 / 22, s.height * 3 / 22)
        ..lineTo(s.width * 19 / 22, s.height * 9.5 / 22)
        ..lineTo(s.width * 19 / 22, s.height * 19 / 22)
        ..arcToPoint(Offset(s.width * 18 / 22, s.height * 20 / 22),
            radius: const Radius.circular(1), clockwise: false)
        ..lineTo(s.width * 4 / 22, s.height * 20 / 22)
        ..arcToPoint(Offset(s.width * 3 / 22, s.height * 19 / 22),
            radius: const Radius.circular(1), clockwise: false)
        ..close();

      // Door cutout
      final door = Path()
        ..addRRect(RRect.fromRectAndCorners(
          Rect.fromLTWH(
            s.width * 8 / 22, s.height * 12.5 / 22,
            s.width * 6 / 22, s.height * 7.5 / 22,
          ),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ));

      final house = Path.combine(PathOperation.difference, body, door);
      canvas.drawPath(house, fillPaint);
    } else {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final roof = Path()
        ..moveTo(s.width * 3 / 22, s.height * 9.5 / 22)
        ..lineTo(s.width * 11 / 22, s.height * 3 / 22)
        ..lineTo(s.width * 19 / 22, s.height * 9.5 / 22)
        ..lineTo(s.width * 19 / 22, s.height * 19 / 22)
        ..arcToPoint(Offset(s.width * 18 / 22, s.height * 20 / 22),
            radius: const Radius.circular(1), clockwise: false)
        ..lineTo(s.width * 4 / 22, s.height * 20 / 22)
        ..arcToPoint(Offset(s.width * 3 / 22, s.height * 19 / 22),
            radius: const Radius.circular(1), clockwise: false)
        ..close();
      canvas.drawPath(roof, p);

      final door = Path()
        ..moveTo(s.width * 8 / 22, s.height * 20 / 22)
        ..lineTo(s.width * 8 / 22, s.height * 13 / 22)
        ..lineTo(s.width * 14 / 22, s.height * 13 / 22)
        ..lineTo(s.width * 14 / 22, s.height * 20 / 22);
      canvas.drawPath(door, p);
    }
  }

  @override
  bool shouldRepaint(_HomeIconPainter old) =>
      old.color != color || old.filled != filled;
}
