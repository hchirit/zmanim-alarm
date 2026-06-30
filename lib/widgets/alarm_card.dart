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

  String _nextTriggerText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsProvider>();
    final calc = settings.calculator;

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
      return '$timeStr · $relStr';
    }
    return l10n.inactive;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.read<SettingsProvider>().locale;
    final zmanColor = alarm.zmanType.color;

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.deleteAlarmTitle,
                style: TextStyle(color: t.appText)),
            content: Text(l10n.deleteAlarmConfirm(alarm.name),
                style: TextStyle(color: t.appMid)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete,
                    style: const TextStyle(color: Colors.red)),
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
                color: alarm.isEnabled
                    ? zmanColor.withValues(alpha: 0.3)
                    : t.appBorder,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: alarm.isEnabled
                          ? zmanColor.withValues(alpha: 0.15)
                          : t.appBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      alarm.zmanType.icon,
                      color: alarm.isEnabled ? zmanColor : t.appSubtle,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.name,
                          style: TextStyle(
                            color: alarm.isEnabled ? t.appText : t.appSubtle,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                alarm.zmanType.hebrewName,
                                style: TextStyle(
                                  color: alarm.isEnabled
                                      ? zmanColor
                                      : t.appSubtle,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (alarm.offsetMinutes != 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: alarm.isEnabled
                                      ? zmanColor.withValues(alpha: 0.1)
                                      : t.appBorder,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  alarm.offsetDescription(locale),
                                  style: TextStyle(
                                    color: alarm.isEnabled
                                        ? zmanColor.withValues(alpha: 0.8)
                                        : t.appSubtle,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.repeat, size: 12, color: t.appSubtle),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                alarm.daysDescription(locale),
                                style: TextStyle(
                                  color: t.appSubtle,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (alarm.isEnabled) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _nextTriggerText(context),
                                  style: TextStyle(
                                    color: zmanColor.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () async {
                      final locale = context.read<SettingsProvider>().locale;
                      await AlarmService.instance.testAlarm(alarm, locale: locale);
                      if (context.mounted) {
                        final dur = alarm.ringDurationSeconds;
                        final msg = dur > 0
                            ? l10n.testingRingWithDuration(
                                alarm.ringDurationDescription(locale))
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
                        color: t.appSubtle, size: 22),
                    tooltip: l10n.testTooltip,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: (_) => context.read<AlarmProvider>().toggleAlarm(
                        alarm,
                        locale: context.read<SettingsProvider>().locale,
                      ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
