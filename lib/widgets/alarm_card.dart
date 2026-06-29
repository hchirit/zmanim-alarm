import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../models/zman_type.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';
import '../services/alarm_service.dart';
import '../services/zmanim_calculator.dart';
import '../theme/app_theme.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onTap;

  const AlarmCard({super.key, required this.alarm, required this.onTap});

  String _nextTriggerText(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final calc = ZmanimCalculator(
      latitude: settings.location.latitude,
      longitude: settings.location.longitude,
      elevation: settings.location.elevation,
    );

    final now = DateTime.now();
    for (int d = 0; d < 8; d++) {
      final date = now.add(Duration(days: d));
      if (!alarm.daysOfWeek.contains(date.weekday)) continue;

      final zmanTime = calc.getZman(alarm.zmanType, date);
      if (zmanTime == null) continue;

      final trigger = zmanTime.add(Duration(minutes: alarm.offsetMinutes));
      if (trigger.isBefore(now)) continue;

      final diff = trigger.difference(now);
      if (diff.inDays > 0) {
        return 'Dans ${diff.inDays}j ${diff.inHours % 24}h';
      } else if (diff.inHours > 0) {
        return 'Dans ${diff.inHours}h ${diff.inMinutes % 60}min';
      } else {
        return 'Dans ${diff.inMinutes} min';
      }
    }
    return 'Inactif';
  }

  @override
  Widget build(BuildContext context) {
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
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Supprimer l\'alarme',
                style: TextStyle(color: AppTheme.onSurface)),
            content: Text('Supprimer "${alarm.name}" ?',
                style: const TextStyle(color: Color(0xFF8BAFC9))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<AlarmProvider>().deleteAlarm(alarm);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${alarm.name}" supprimée')),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alarm.isEnabled
                  ? zmanColor.withValues(alpha: 0.3)
                  : const Color(0xFF1E3A52),
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
                        : const Color(0xFF1E3A52),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alarm.zmanType.icon,
                    color: alarm.isEnabled ? zmanColor : const Color(0xFF4A6B85),
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
                          color: alarm.isEnabled
                              ? AppTheme.onSurface
                              : const Color(0xFF4A6B85),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            alarm.zmanType.hebrewName,
                            style: TextStyle(
                              color: alarm.isEnabled
                                  ? zmanColor
                                  : const Color(0xFF4A6B85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                                    : const Color(0xFF1E3A52),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alarm.offsetDescription,
                                style: TextStyle(
                                  color: alarm.isEnabled
                                      ? zmanColor.withValues(alpha: 0.8)
                                      : const Color(0xFF4A6B85),
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
                          Icon(
                            Icons.repeat,
                            size: 12,
                            color: const Color(0xFF4A6B85),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              alarm.daysDescription,
                              style: const TextStyle(
                                color: Color(0xFF4A6B85),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (alarm.isEnabled) ...[
                            const SizedBox(width: 8),
                            Text(
                              _nextTriggerText(context),
                              style: TextStyle(
                                color: zmanColor.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                    await AlarmService.instance.testAlarm(alarm);
                    if (context.mounted) {
                      final dur = alarm.ringDurationSeconds;
                      final msg = dur > 0
                          ? 'Sonnerie dans 5 secondes… (s\'arrête après ${alarm.ringDurationDescription})'
                          : 'Sonnerie dans 5 secondes…';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline,
                      color: Color(0xFF4A6B85), size: 22),
                  tooltip: 'Tester',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (_) =>
                      context.read<AlarmProvider>().toggleAlarm(alarm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
