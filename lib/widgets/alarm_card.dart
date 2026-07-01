import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../models/zman_type.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onTap;

  const AlarmCard({super.key, required this.alarm, required this.onTap});

  ({String time, String countdown})? _nextTrigger(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calc = context.read<SettingsProvider>().calculator;
    final now = DateTime.now();

    for (int d = 0; d < 8; d++) {
      final date = now.add(Duration(days: d));
      if (!alarm.daysOfWeek.contains(date.weekday)) continue;

      final zmanTime = calc.getZman(alarm.zmanType, date);
      if (zmanTime == null) continue;

      final trigger = zmanTime.add(Duration(minutes: alarm.offsetMinutes));
      if (trigger.isBefore(now)) continue;

      final timeStr = DateFormat('HH:mm').format(trigger);
      final diff = trigger.difference(now);
      final relStr = diff.inDays > 0
          ? l10n.inDaysHours(diff.inDays, diff.inHours % 24)
          : diff.inHours > 0
              ? l10n.inHoursMinutes(diff.inHours, diff.inMinutes % 60)
              : l10n.inMinutes(diff.inMinutes);
      return (time: timeStr, countdown: relStr);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.read<SettingsProvider>().locale;
    final zmanColor = alarm.zmanType.color;
    final methodKey = alarm.zmanType.calculationMethodKey;

    return Dismissible(
      key: Key('alarm_${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
      ),
      confirmDismiss: (_) async {
        final t = Theme.of(context);
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: t.appCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.deleteAlarmTitle, style: TextStyle(color: t.appText)),
            content: Text(l10n.deleteAlarmConfirm(alarm.name), style: TextStyle(color: t.appMid)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<AlarmProvider>().deleteAlarm(alarm);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.alarmDeleted(alarm.name))),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Builder(builder: (context) {
          final t = Theme.of(context);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: t.appCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: alarm.isEnabled ? zmanColor.withValues(alpha: 0.3) : t.appBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Rangée 1 : icône + nom + boutons ─────────────────────
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: alarm.isEnabled
                              ? zmanColor.withValues(alpha: 0.15)
                              : t.appBorder,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          alarm.zmanType.icon,
                          color: alarm.isEnabled ? zmanColor : t.appSubtle,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          alarm.name,
                          style: TextStyle(
                            color: alarm.isEnabled ? t.appText : t.appSubtle,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final loc = context.read<SettingsProvider>().locale;
                          await AlarmService.instance.testAlarm(alarm, locale: loc);
                          if (context.mounted) {
                            final dur = alarm.ringDurationSeconds;
                            final msg = dur > 0
                                ? l10n.testingRingWithDuration(
                                    alarm.ringDurationDescription(loc))
                                : l10n.testingRing;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.play_circle_outline,
                            color: t.appSubtle, size: 20),
                        tooltip: l10n.testTooltip,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Switch(
                        value: alarm.isEnabled,
                        onChanged: (_) =>
                            context.read<AlarmProvider>().toggleAlarm(
                                  alarm,
                                  locale:
                                      context.read<SettingsProvider>().locale,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ── Rangée 2 : zman + badges + jours ─────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                alarm.zmanType.localizedName(locale),
                                style: TextStyle(
                                  color: alarm.isEnabled
                                      ? zmanColor
                                      : t.appSubtle,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (methodKey != null) ...[
                              const SizedBox(width: 5),
                              _InfoBadge(
                                label: methodKey,
                                color: zmanColor,
                                enabled: alarm.isEnabled,
                              ),
                            ],
                            if (alarm.offsetMinutes != 0) ...[
                              const SizedBox(width: 5),
                              _InfoBadge(
                                label: alarm.offsetDescription(locale),
                                color: zmanColor,
                                enabled: alarm.isEnabled,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 11, color: t.appSubtle),
                          const SizedBox(width: 4),
                          Text(
                            alarm.daysDescription(locale),
                            style: TextStyle(color: t.appSubtle, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ── Rangée 3 : prochain déclenchement ────────────────────
                  Builder(builder: (context) {
                    if (!alarm.isEnabled) return _InactiveRow(l10n: l10n);
                    final next = _nextTrigger(context);
                    if (next == null) return _InactiveRow(l10n: l10n);
                    return _TriggerBanner(
                      time: next.time,
                      countdown: next.countdown,
                      color: zmanColor,
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bannière de déclenchement ─────────────────────────────────────────────────

class _TriggerBanner extends StatelessWidget {
  final String time;
  final String countdown;
  final Color color;

  const _TriggerBanner({
    required this.time,
    required this.countdown,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 14, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 22, color: color.withValues(alpha: 0.25)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              countdown,
              style: TextStyle(color: t.appMid, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alarme inactive ───────────────────────────────────────────────────────────

class _InactiveRow extends StatelessWidget {
  final AppLocalizations l10n;
  const _InactiveRow({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.access_time_outlined, size: 13, color: t.appSubtle),
        const SizedBox(width: 6),
        Text(l10n.inactive, style: TextStyle(color: t.appSubtle, fontSize: 12)),
      ],
    );
  }
}

// ── Badge d'information (méthode, offset) ────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;

  const _InfoBadge({
    required this.label,
    required this.color,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.12) : t.appBorder,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? color : t.appSubtle,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
