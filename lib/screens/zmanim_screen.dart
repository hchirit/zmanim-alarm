import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/zman_type.dart';
import '../providers/settings_provider.dart';
import '../services/zmanim_calculator.dart';
import '../theme/app_theme.dart';

class ZmanimScreen extends StatefulWidget {
  final bool embedded;

  const ZmanimScreen({super.key, this.embedded = false});

  @override
  State<ZmanimScreen> createState() => _ZmanimScreenState();
}

class _ZmanimScreenState extends State<ZmanimScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (!settings.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final calc = ZmanimCalculator(
      latitude: settings.location.latitude,
      longitude: settings.location.longitude,
      elevation: settings.location.elevation,
    );

    final zmanim = calc.getAllZmanim(_selectedDate);
    final now = DateTime.now();

    // Sort by time
    final sorted = zmanim.entries
        .where((e) => e.value != null)
        .toList()
      ..sort((a, b) => a.value!.compareTo(b.value!));

    // Find next upcoming
    ZmanType? nextType;
    for (final e in sorted) {
      if (e.value!.isAfter(now)) {
        nextType = e.key;
        break;
      }
    }

    return Column(
      children: [
        _DatePicker(
          date: _selectedDate,
          onChanged: (d) => setState(() => _selectedDate = d),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final entry = sorted[index];
              final isNext = entry.key == nextType;
              final isPast = entry.value!.isBefore(now) &&
                  _selectedDate.day == now.day &&
                  _selectedDate.month == now.month &&
                  _selectedDate.year == now.year;

              return _ZmanRow(
                zmanType: entry.key,
                time: entry.value!,
                isNext: isNext,
                isPast: isPast,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                onChanged(date.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryBlue,
                        surface: AppTheme.cardDark,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) onChanged(picked);
              },
              child: Column(
                children: [
                  Text(
                    isToday
                        ? "Aujourd'hui"
                        : DateFormat('EEEE', 'fr_FR').format(date),
                    style: TextStyle(
                      color: isToday ? AppTheme.gold : const Color(0xFF8BAFC9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy', 'fr_FR').format(date),
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(date.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ZmanRow extends StatelessWidget {
  final ZmanType zmanType;
  final DateTime time;
  final bool isNext;
  final bool isPast;

  const _ZmanRow({
    required this.zmanType,
    required this.time,
    required this.isNext,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPast
        ? const Color(0xFF2D4A62)
        : isNext
            ? zmanType.color
            : zmanType.color.withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isNext
            ? zmanType.color.withValues(alpha: 0.08)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext
              ? zmanType.color.withValues(alpha: 0.4)
              : const Color(0xFF1E3A52),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isPast ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(zmanType.icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zmanType.hebrewName,
                    style: TextStyle(
                      color: isPast ? const Color(0xFF2D4A62) : AppTheme.onSurface,
                      fontSize: 14,
                      fontWeight:
                          isNext ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    zmanType.frenchName,
                    style: TextStyle(
                      color: isPast
                          ? const Color(0xFF1E3A52)
                          : const Color(0xFF4A6B85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight:
                        isNext ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: zmanType.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Suivant',
                      style: TextStyle(
                        color: zmanType.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
