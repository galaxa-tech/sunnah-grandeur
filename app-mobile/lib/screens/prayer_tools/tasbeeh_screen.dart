import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/local/tasbih_service.dart';
import '../../providers/profile_stats_provider.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  static const _dhikrs  = ['SubhanAllah', 'Alhamdulillah', 'Allahu Akbar', 'Astaghfirullah'];
  static const _targets = [33, 33, 34, 100];
  static const _arabic  = ['سبحان الله', 'الحمد لله', 'الله أكبر', 'أستغفر الله'];

  int _selectedDhikr = 0;

  // Displayed state — all initialised to 0, loaded from TasbihService in initState
  int _count    = 0;
  int _rounds   = 0;
  int _today    = 0;
  int _lifetime = 0;

  bool _loaded = false;

  late AnimationController _tapCtrl;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
    _loadState();
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final state = await TasbihService.load(_dhikrs[_selectedDhikr]);
    if (!mounted) return;
    setState(() {
      _count    = state.totalCount % _targets[_selectedDhikr];
      _rounds   = state.rounds;
      _today    = state.todayCount;
      _lifetime = state.totalCount;
      _loaded   = true;
    });
  }

  Future<void> _selectDhikr(int i) async {
    setState(() { _selectedDhikr = i; _loaded = false; });
    final state = await TasbihService.load(_dhikrs[i]);
    if (!mounted) return;
    setState(() {
      _count    = state.totalCount % _targets[i];
      _rounds   = state.rounds;
      _today    = state.todayCount;
      _lifetime = state.totalCount;
      _loaded   = true;
    });
  }

  Future<void> _onTap() async {
    HapticFeedback.lightImpact();
    _tapCtrl.forward().then((_) => _tapCtrl.reverse());

    final state = await TasbihService.increment(
      _dhikrs[_selectedDhikr],
      target: _targets[_selectedDhikr],
    );
    if (!mounted) return;
    setState(() {
      _count    = state.totalCount % _targets[_selectedDhikr];
      _rounds   = state.rounds;
      _today    = state.todayCount;
      _lifetime = state.totalCount;
    });
    // Keep the Profile screen's lifetime tasbeeh stat in sync.
    context.read<ProfileStatsProvider>().refresh();
  }

  Future<void> _onReset() async {
    await TasbihService.resetSession(_dhikrs[_selectedDhikr]);
    if (!mounted) return;
    setState(() { _count = 0; _rounds = 0; });
  }

  @override
  Widget build(BuildContext context) {
    final c       = AppColors.of(context);
    final target  = _targets[_selectedDhikr];
    final progress = _loaded ? (_count / target).clamp(0.0, 1.0) : 0.0;
    final arabic  = _arabic[_selectedDhikr];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(children: [
              _BackBtn(c: c),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tasbih', style: AppTextStyles.brandSmall(c)),
                  Text('Digital Dhikr Counter', style: AppTextStyles.brandTag(c)),
                ],
              )),
              GestureDetector(
                onTap: _onReset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.isDark ? c.surf : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.bd2),
                  ),
                  child: Text('Reset', style: AppTextStyles.bodyMuted(c, size: 10)),
                ),
              ),
            ]),
          ),

          // Dhikr selector chips
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              itemCount: _dhikrs.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _selectDhikr(i),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedDhikr == i ? c.gold : (c.isDark ? c.surf : Colors.white),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _selectedDhikr == i ? c.gold3 : c.bd2),
                  ),
                  child: Text(_dhikrs[i],
                    style: AppTextStyles.pill(c,
                      color: _selectedDhikr == i ? Colors.white : c.t3,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Counter body
          Expanded(
            child: !_loaded
              ? Center(child: CircularProgressIndicator(color: c.gold))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_dhikrs[_selectedDhikr], style: AppTextStyles.italic(c, fontSize: 14)),
                    const SizedBox(height: 8),

                    // Big count (session count within current round)
                    Text('$_count', style: AppTextStyles.displayXl(c)),
                    Text('/ $target',
                      style: AppTextStyles.displaySm(c, color: c.t3)
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w300)),

                    const SizedBox(height: 24),

                    // Progress bar
                    SizedBox(
                      width: 190,
                      child: Column(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            color: c.gold, backgroundColor: c.bd,
                            minHeight: 2.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0', style: AppTextStyles.bodyMuted(c, size: 9)),
                            Text('${(progress * 100).round()}%', style: AppTextStyles.pill(c, size: 9)),
                            Text('$target', style: AppTextStyles.bodyMuted(c, size: 9)),
                          ],
                        ),
                      ]),
                    ),

                    const SizedBox(height: 30),

                    // Tap circle button
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: GestureDetector(
                        onTap: _onTap,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(width: 182, height: 182,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                border: Border.all(color: c.gold.withValues(alpha: 0.05)))),
                          Container(width: 166, height: 166,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                border: Border.all(color: c.gold.withValues(alpha: 0.09)))),
                          Container(
                            width: 148, height: 148,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.2, -0.3), radius: 0.85,
                                colors: [c.gold.withValues(alpha: 0.13), c.gold.withValues(alpha: 0.04)],
                              ),
                              border: Border.all(color: c.gold.withValues(alpha: 0.28), width: 1.5),
                              boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(arabic, style: AppTextStyles.displaySm(c).copyWith(fontSize: 18, height: 1)),
                                const SizedBox(height: 5),
                                Text('Tap to count', style: AppTextStyles.cinzelSm(c, size: 8).copyWith(letterSpacing: 0.14 * 8)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Stats row
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _CountStat(c: c, value: '$_rounds',   label: 'rounds'),
                      _Divider(c: c),
                      _CountStat(c: c, value: '$_today',    label: 'today'),
                      _Divider(c: c),
                      _CountStat(c: c, value: '$_lifetime', label: 'lifetime'),
                    ]),
                  ],
                ),
          ),
        ]),
      ),
    );
  }
}

class _CountStat extends StatelessWidget {
  const _CountStat({required this.c, required this.value, required this.label});
  final AppColors c;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: AppTextStyles.displaySm(c).copyWith(fontSize: 22)),
      Text(label, style: AppTextStyles.bodyMuted(c, size: 9)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 26,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: c.bd2,
  );
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: c.surf, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.bd2),
        ),
        child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20),
      ),
    );
  }
}
