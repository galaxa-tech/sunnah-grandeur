import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home/home_screen.dart';
import 'media/media_hub_screen.dart';
import 'store/store_screen.dart';
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

  // Keep all navigator states alive between tab switches.
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _roots = const [
    HomeScreen(),
    MediaHubScreen(),
    StoreScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Pop to root if already on tab
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
  });
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: c.bg2,
        border: Border(top: BorderSide(color: c.bd, width: 1)),
      ),
      child: Row(children: [
        _NavItem(icon: _homeIcon,    label: labels[0], isOn: currentIndex == 0, onTap: () => onTap(0), c: c),
        _NavItem(icon: _mediaIcon,   label: labels[1], isOn: currentIndex == 1, onTap: () => onTap(1), c: c),
        _NavItem(icon: _storeIcon,   label: labels[2], isOn: currentIndex == 2, onTap: () => onTap(2), c: c),
        _NavItem(icon: _profileIcon, label: labels[3], isOn: currentIndex == 3, onTap: () => onTap(3), c: c),
      ]),
    );
  }

  // SVG-matched icon builders
  Widget _homeIcon(Color color) => CustomPaint(
    size: const Size(22, 22),
    painter: _HomeIconPainter(color),
  );
  Widget _mediaIcon(Color color) => Icon(Icons.play_circle_outline_rounded,
      color: color, size: 22);
  Widget _storeIcon(Color color) => Icon(Icons.shopping_cart_outlined,
      color: color, size: 22);
  Widget _profileIcon(Color color) => Icon(Icons.person_outline_rounded,
      color: color, size: 22);
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onTap,
    required this.c,
  });
  final Widget Function(Color) icon;
  final String label;
  final bool isOn;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final color = isOn ? c.gold : c.t3;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 9),
            icon(color),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.pill(c, color: color, size: 9.5)),
          ],
        ),
      ),
    );
  }
}

// ── Home icon custom painter ──────────────────────────────────────────────────
class _HomeIconPainter extends CustomPainter {
  _HomeIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size;
    // Roof path: M3 9.5L11 3l8 6.5V19a1 1 0 01-1 1H4a1 1 0 01-1-1V9.5z
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

    // Door: M8 20V13h6v7
    final door = Path()
      ..moveTo(s.width * 8 / 22, s.height * 20 / 22)
      ..lineTo(s.width * 8 / 22, s.height * 13 / 22)
      ..lineTo(s.width * 14 / 22, s.height * 13 / 22)
      ..lineTo(s.width * 14 / 22, s.height * 20 / 22);
    canvas.drawPath(door, p);
  }

  @override
  bool shouldRepaint(_HomeIconPainter old) => old.color != color;
}
