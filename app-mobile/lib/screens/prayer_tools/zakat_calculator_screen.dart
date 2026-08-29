import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Placeholder market prices — clearly labelled in the UI as needing an
  // up-to-date value; there is no bundled live gold/silver price feed.
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
                  Text('Zakat Calculator', style: AppTextStyles.heading(c, fontSize: 19)),
                  Text('CALCULATE YOUR ANNUAL ZAKAT', style: AppTextStyles.brandTag(c)),
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
                    color: c.gold.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.gold.withOpacity(0.16)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: c.goldSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.gold.withOpacity(0.22)),
                        ),
                        child: Icon(Icons.info_outline_rounded, color: c.gold, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About Zakat', style: AppTextStyles.displaySm(c).copyWith(fontSize: 14)),
                            const SizedBox(height: 3),
                            Text(
                              'Zakat is due once your total zakatable wealth has met or exceeded the Nisab '
                              '(the value of 85g of gold) and has been held for one lunar year. Enter your '
                              'assets below to see what you owe.',
                              style: AppTextStyles.bodyMuted(c, size: 10).copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                EyeRow(label: 'YOUR ZAKATABLE ASSETS'),
                _AmountField(
                  c: c, label: 'Cash & Savings',
                  hint: 'Bank balances, cash on hand',
                  controller: _cashCtrl,
                ),
                _AmountField(
                  c: c, label: 'Gold You Own (grams)',
                  hint: 'Total weight of gold owned',
                  controller: _goldGramsCtrl,
                  suffix: 'g',
                ),
                _AmountField(
                  c: c, label: 'Silver You Own (grams)',
                  hint: 'Total weight of silver owned',
                  controller: _silverGramsCtrl,
                  suffix: 'g',
                ),
                _AmountField(
                  c: c, label: 'Business Assets / Inventory',
                  hint: 'Value of stock-in-trade & receivables',
                  controller: _businessCtrl,
                ),
                _AmountField(
                  c: c, label: 'Other Investments',
                  hint: 'Stocks, crypto, other zakatable holdings',
                  controller: _investmentsCtrl,
                ),

                const SizedBox(height: 6),
                EyeRow(
                  label: 'CURRENT MARKET PRICES',
                  trailing: const SgPill(label: 'Update with today\'s price', variant: 'gold', fontSize: 7.5),
                ),
                _AmountField(
                  c: c, label: 'Gold Price (per gram)',
                  hint: 'Used for gold value & Nisab threshold',
                  controller: _goldPriceCtrl,
                  prefix: '\$',
                ),
                _AmountField(
                  c: c, label: 'Silver Price (per gram)',
                  hint: 'Used for silver value',
                  controller: _silverPriceCtrl,
                  prefix: '\$',
                ),

                const SizedBox(height: 10),
                EyeRow(label: 'RESULT'),
                _ResultCard(
                  c: c,
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
    required this.totalWealth,
    required this.nisab,
    required this.meetsNisab,
    required this.zakatDue,
    required this.goldValue,
    required this.silverValue,
  });

  final AppColors c;
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
          Text('TOTAL ZAKATABLE WEALTH', style: AppTextStyles.brandTag(c)),
          Text(_fmt(totalWealth), style: AppTextStyles.body(c, size: 13, weight: FontWeight.w600)),
        ]),
        if (goldValue > 0 || silverValue > 0) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('  Gold + Silver value', style: AppTextStyles.bodyMuted(c, size: 10)),
            Text(_fmt(goldValue + silverValue), style: AppTextStyles.bodyMuted(c, size: 10)),
          ]),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('NISAB THRESHOLD (85g GOLD)', style: AppTextStyles.brandTag(c).copyWith(color: c.t3)),
          Text(_fmt(nisab), style: AppTextStyles.body(c, size: 13, color: c.t2)),
        ]),
        const SizedBox(height: 14),
        Divider(color: c.gold.withOpacity(0.18), height: 1),
        const SizedBox(height: 14),
        if (meetsNisab) ...[
          Row(children: [
            Icon(Icons.check_circle_rounded, color: c.green, size: 18),
            const SizedBox(width: 8),
            Text('Zakat is due this year', style: AppTextStyles.heading(c, fontSize: 14, color: c.green)),
          ]),
          const SizedBox(height: 10),
          Text('ZAKAT DUE (2.5%)', style: AppTextStyles.brandTag(c)),
          const SizedBox(height: 2),
          Text(_fmt(zakatDue), style: AppTextStyles.displaySm(c).copyWith(fontSize: 30, color: c.gold)),
        ] else ...[
          Row(children: [
            Icon(Icons.info_outline_rounded, color: c.t3, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your total wealth is below the Nisab threshold — no Zakat is due this year.',
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
