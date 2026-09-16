import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/metal_prices_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/sg_pill.dart';

/// Zakat Calculator — a self-contained tool screen (no app-wide provider
/// needed, matching the pattern of TasbeehScreen / ForbiddenTimesScreen:
/// the calculation is simple, derived state that only this screen cares
/// about, so plain StatefulWidget local state is the right fit here).
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  // Standard Zakat reference values.
  static const double _nisabGoldGrams = 85.0;
  static const double _zakatRate = 0.025; // 2.5%

  // Fallback values shown while the live price (see MetalPricesService)
  // loads, or if that fetch fails — always editable either way.
  static const double _defaultGoldPricePerGram = 75.0;
  static const double _defaultSilverPricePerGram = 0.95;

  final _cashCtrl = TextEditingController();
  final _goldGramsCtrl = TextEditingController();
  final _silverGramsCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _investmentsCtrl = TextEditingController();
  final _goldPriceCtrl =
      TextEditingController(text: _defaultGoldPricePerGram.toStringAsFixed(2));
  final _silverPriceCtrl = TextEditingController(
      text: _defaultSilverPricePerGram.toStringAsFixed(2));

  bool _loadingLivePrices = false;
  bool _usingLivePrices = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _cashCtrl,
      _goldGramsCtrl,
      _silverGramsCtrl,
      _businessCtrl,
      _investmentsCtrl,
      _goldPriceCtrl,
      _silverPriceCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
    _refreshLivePrices();
  }

  Future<void> _refreshLivePrices() async {
    setState(() => _loadingLivePrices = true);
    final prices = await MetalPricesService.instance.fetchLivePrices();
    if (!mounted) return;
    setState(() {
      _loadingLivePrices = false;
      if (prices != null) {
        _goldPriceCtrl.text = prices.goldUsdPerGram.toStringAsFixed(2);
        _silverPriceCtrl.text = prices.silverUsdPerGram.toStringAsFixed(2);
        _usingLivePrices = true;
      }
    });
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _goldGramsCtrl.dispose();
    _silverGramsCtrl.dispose();
    _businessCtrl.dispose();
    _investmentsCtrl.dispose();
    _goldPriceCtrl.dispose();
    _silverPriceCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    final cash = _num(_cashCtrl);
    final goldGrams = _num(_goldGramsCtrl);
    final silverGrams = _num(_silverGramsCtrl);
    final business = _num(_businessCtrl);
    final investments = _num(_investmentsCtrl);
    final goldPrice = _num(_goldPriceCtrl);
    final silverPrice = _num(_silverPriceCtrl);

    final goldValue = goldGrams * goldPrice;
    final silverValue = silverGrams * silverPrice;
    final totalWealth = cash + goldValue + silverValue + business + investments;
    final nisab = goldPrice * _nisabGoldGrams;
    final meetsNisab = nisab > 0 && totalWealth >= nisab;
    final zakatDue = meetsNisab ? totalWealth * _zakatRate : 0.0;

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
                  Text(lang.tr('zakat_calculator'), style: AppTextStyles.heading(c, fontSize: 19)),
                  Text(lang.tr('zakat_calc_tag'), style: AppTextStyles.brandTag(c)),
                ],
              )),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Intro banner
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.gold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.gold.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: c.goldSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                        ),
                        child: Icon(Icons.info_outline_rounded, color: c.gold, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang.tr('about_zakat'), style: AppTextStyles.displaySm(c).copyWith(fontSize: 14)),
                            const SizedBox(height: 3),
                            Text(
                              lang.tr('about_zakat_body'),
                              style: AppTextStyles.bodyMuted(c, size: 10).copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                EyeRow(label: lang.tr('your_zakatable_assets')),
                _AmountField(
                  c: c, label: lang.tr('cash_savings'),
                  hint: lang.tr('cash_savings_hint'),
                  controller: _cashCtrl,
                ),
                _AmountField(
                  c: c, label: lang.tr('gold_owned'),
                  hint: lang.tr('gold_owned_hint'),
                  controller: _goldGramsCtrl,
                  suffix: 'g',
                ),
                _AmountField(
                  c: c, label: lang.tr('silver_owned'),
                  hint: lang.tr('silver_owned_hint'),
                  controller: _silverGramsCtrl,
                  suffix: 'g',
                ),
                _AmountField(
                  c: c, label: lang.tr('business_assets'),
                  hint: lang.tr('business_assets_hint'),
                  controller: _businessCtrl,
                ),
                _AmountField(
                  c: c, label: lang.tr('other_investments'),
                  hint: lang.tr('other_investments_hint'),
                  controller: _investmentsCtrl,
                ),

                const SizedBox(height: 6),
                EyeRow(
                  label: lang.tr('current_market_prices'),
                  trailing: GestureDetector(
                    onTap: _loadingLivePrices ? null : _refreshLivePrices,
                    child: _loadingLivePrices
                        ? SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: c.gold),
                          )
                        : SgPill(
                            label: _usingLivePrices
                                ? lang.tr('live_price_refresh')
                                : lang.tr('tap_fetch_price'),
                            variant: 'gold',
                            fontSize: 7.5,
                          ),
                  ),
                ),
                _AmountField(
                  c: c, label: lang.tr('gold_price_gram'),
                  hint: lang.tr('gold_price_gram_hint'),
                  controller: _goldPriceCtrl,
                  prefix: '\$',
                ),
                _AmountField(
                  c: c, label: lang.tr('silver_price_gram'),
                  hint: lang.tr('silver_price_gram_hint'),
                  controller: _silverPriceCtrl,
                  prefix: '\$',
                ),

                const SizedBox(height: 10),
                EyeRow(label: lang.tr('zakat_result')),
                _ResultCard(
                  c: c,
                  lang: lang,
                  totalWealth: totalWealth,
                  nisab: nisab,
                  meetsNisab: meetsNisab,
                  zakatDue: zakatDue,
                  goldValue: goldValue,
                  silverValue: silverValue,
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Amount input field ────────────────────────────────────────────────────
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.c,
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.suffix,
  });

  final AppColors c;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label(c, size: 12.5)),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: AppTextStyles.bodyMuted(c, size: 9.5)),
          ],
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.bd2),
            ),
            child: Row(children: [
              if (prefix != null) ...[
                Text(prefix!, style: AppTextStyles.body(c, size: 14, color: c.t3)),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: AppTextStyles.body(c, size: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0.00',
                    hintStyle: AppTextStyles.body(c, size: 14, color: c.t3),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix!, style: AppTextStyles.body(c, size: 12, color: c.t3)),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Result card ────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.c,
    required this.lang,
    required this.totalWealth,
    required this.nisab,
    required this.meetsNisab,
    required this.zakatDue,
    required this.goldValue,
    required this.silverValue,
  });

  final AppColors c;
  final LanguageProvider lang;
  final double totalWealth;
  final double nisab;
  final bool meetsNisab;
  final double zakatDue;
  final double goldValue;
  final double silverValue;

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    // Simple thousands separator without pulling in a formatting package.
    final parts = s.split('.');
    final whole = parts[0];
    final buf = StringBuffer();
    final negative = whole.startsWith('-');
    final digits = negative ? whole.substring(1) : whole;
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buf.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return '${negative ? '-' : ''}\$$buf.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: c.goldCardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lang.tr('total_zakatable_wealth'), style: AppTextStyles.brandTag(c)),
          Text(_fmt(totalWealth), style: AppTextStyles.body(c, size: 13, weight: FontWeight.w600)),
        ]),
        if (goldValue > 0 || silverValue > 0) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('  ${lang.tr('gold_silver_value')}', style: AppTextStyles.bodyMuted(c, size: 10)),
            Text(_fmt(goldValue + silverValue), style: AppTextStyles.bodyMuted(c, size: 10)),
          ]),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lang.tr('nisab_threshold'), style: AppTextStyles.brandTag(c).copyWith(color: c.t3)),
          Text(_fmt(nisab), style: AppTextStyles.body(c, size: 13, color: c.t2)),
        ]),
        const SizedBox(height: 14),
        Divider(color: c.gold.withValues(alpha: 0.18), height: 1),
        const SizedBox(height: 14),
        if (meetsNisab) ...[
          Row(children: [
            Icon(Icons.check_circle_rounded, color: c.green, size: 18),
            const SizedBox(width: 8),
            Text(lang.tr('zakat_due_this_year'), style: AppTextStyles.heading(c, fontSize: 14, color: c.green)),
          ]),
          const SizedBox(height: 10),
          Text(lang.tr('zakat_due_pct'), style: AppTextStyles.brandTag(c)),
          const SizedBox(height: 2),
          Text(_fmt(zakatDue), style: AppTextStyles.displaySm(c).copyWith(fontSize: 30, color: c.gold)),
        ] else ...[
          Row(children: [
            Icon(Icons.info_outline_rounded, color: c.t3, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lang.tr('below_nisab_notice'),
                style: AppTextStyles.body(c, size: 12.5, color: c.t2),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ── Shared back button (matches other prayer-tool screens) ─────────────────
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
