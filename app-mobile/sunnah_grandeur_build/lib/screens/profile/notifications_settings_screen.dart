import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _masterToggle = true;
  bool _fajr = true;
  bool _dhuhr = true;
  bool _asr = false;
  bool _maghrib = true;
  bool _isha = false;
  bool _sehri = false;
  bool _jumuah = true;
  
  String _alertStyle = 'Azaan';

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
                        Text('Notifications', style: AppTextStyles.heading(c, fontSize: 19)),
                        Text('PRAYER ALERTS & REMINDERS', style: AppTextStyles.brandTag(c)),
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
                    // Master toggle card
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      padding: const EdgeInsets.all(18),
                      decoration: c.goldCardDecoration.copyWith(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.gold.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All Notifications', style: AppTextStyles.heading(c, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('Master switch for all alerts', style: AppTextStyles.bodyMuted(c, size: 10.5)),
                            ],
                          ),
                          _Toggle(value: _masterToggle, onChanged: (v) => setState(() => _masterToggle = v), c: c),
                        ],
                      ),
                    ),

                    _EyeRow(label: 'Prayer Alerts', c: c),

                    // Prayer notification rows
                    Column(
                      children: [
                        _PrayerRow(name: 'Fajr', sub: '5:12 AM · 5 min before', isActive: _fajr, onChanged: (v) => setState(() => _fajr = v), c: c),
                        _PrayerRow(name: 'Dhuhr', sub: '12:08 PM · At time', isActive: _dhuhr, onChanged: (v) => setState(() => _dhuhr = v), c: c),
                        _PrayerRow(name: 'Asr', sub: '3:47 PM · Off', isActive: _asr, onChanged: (v) => setState(() => _asr = v), c: c),
                        _PrayerRow(name: 'Maghrib', sub: '6:22 PM · At time', isActive: _maghrib, onChanged: (v) => setState(() => _maghrib = v), c: c),
                        _PrayerRow(name: 'Isha', sub: '7:48 PM · Off', isActive: _isha, onChanged: (v) => setState(() => _isha = v), c: c),
                      ],
                    ),

                    _EyeRow(label: 'Other Reminders', c: c),

                    Column(
                      children: [
                        _ReminderRow(icon: Icons.brightness_2_rounded, title: 'Ramadan Sehri Alert', sub: '30 min before Sehri', isActive: _sehri, onChanged: (v) => setState(() => _sehri = v), c: c),
                        _ReminderRow(icon: Icons.location_city_rounded, title: "Jumu'ah Reminder", sub: 'Every Friday, 1:00 PM', isActive: _jumuah, onChanged: (v) => setState(() => _jumuah = v), c: c),
                      ],
                    ),

                    const SizedBox(height: 4),
                    _EyeRow(label: 'Alert Style', c: c),

                    Row(
                      children: [
                        _AlertStyleCard(emoji: '🔔', label: 'Azaan', isEq: _alertStyle == 'Azaan', onTap: () => setState(() => _alertStyle = 'Azaan'), c: c),
                        _AlertStyleCard(emoji: '🔕', label: 'Silent', isEq: _alertStyle == 'Silent', onTap: () => setState(() => _alertStyle = 'Silent'), c: c),
                        _AlertStyleCard(emoji: '📳', label: 'Vibrate', isEq: _alertStyle == 'Vibrate', onTap: () => setState(() => _alertStyle = 'Vibrate'), c: c),
                      ],
                    ),
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

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.name, required this.sub, required this.isActive, required this.onChanged, required this.c});
  final String name, sub;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? c.goldSurface : c.surf,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: isActive ? c.gold.withOpacity(0.16) : c.bd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.heading(c, fontSize: 16)),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.body(c, color: isActive ? c.gold : c.t3, size: 10)),
              ],
            ),
          ),
          _Toggle(value: isActive, onChanged: onChanged, c: c),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.icon, required this.title, required this.sub, required this.isActive, required this.onChanged, required this.c});
  final IconData icon;
  final String title, sub;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.bd),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.gold.withOpacity(0.14)),
            ),
            child: Icon(icon, color: c.gold, size: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(c, size: 13)),
                const SizedBox(height: 1),
                Text(sub, style: AppTextStyles.bodyMuted(c, size: 10)),
              ],
            ),
          ),
          _Toggle(value: isActive, onChanged: onChanged, c: c),
        ],
      ),
    );
  }
}

class _AlertStyleCard extends StatelessWidget {
  const _AlertStyleCard({required this.emoji, required this.label, required this.isEq, required this.onTap, required this.c});
  final String emoji, label;
  final bool isEq;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEq ? c.goldSurface : c.surf,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isEq ? c.gold.withOpacity(0.35) : c.bd, width: isEq ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.body(c, color: isEq ? c.gold : c.t3, size: 11).copyWith(fontWeight: isEq ? FontWeight.w500 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged, required this.c});
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 24,
        decoration: BoxDecoration(
          color: value ? c.gold : c.bd2,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: value ? c.bg : c.t3,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.c});
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.brandTag(c)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.gold.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
