import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sg_pill.dart';

/// Prayer row states.
enum PrayerRowState { upcoming, active, done, optional }

class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.name,
    required this.time,
    this.state = PrayerRowState.upcoming,
    this.badge,
  });

  final String name;
  final String time;
  final PrayerRowState state;
  final String? badge;   // e.g. "Now", "optional"

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isActive   = state == PrayerRowState.active;
    final isDone     = state == PrayerRowState.done;
    final isOptional = state == PrayerRowState.optional;

    Color dotColor;
    if (isActive)       dotColor = c.gold;
    else if (isDone)    dotColor = c.green;
    else                dotColor = c.bd2;

    Color nameColor = isActive ? c.gold : (isOptional ? c.t3 : c.t1);
    Color timeColor = isActive ? c.gold2 : c.t3;

    return Opacity(
      opacity: isOptional ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        isActive ? c.gold.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: isActive ? c.gold.withOpacity(0.18) : Colors.transparent,
          ),
        ),
        child: Row(children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
              style: AppTextStyles.prayerName(c).copyWith(color: nameColor)),
          ),
          Text(time,
            style: AppTextStyles.bodyMuted(c, size: 11)
                .copyWith(
                  color: timeColor,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                )),
          if (isDone) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, color: c.green, size: 14),
          ],
          if (isActive && badge != null) ...[
            const SizedBox(width: 8),
            SgPill(label: badge!, variant: 'gold', fontSize: 8),
          ],
          if (isOptional) ...[
            const SizedBox(width: 7),
            SgPill(label: 'optional', variant: 'gold', fontSize: 7.5),
          ],
        ]),
      ),
    );
  }
}
