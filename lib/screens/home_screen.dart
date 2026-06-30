import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';
import '../services/alarm_service.dart';
import '../services/hebrew_date_service.dart';
import '../services/zmanim_calculator.dart';
import '../models/zman_type.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import 'add_alarm_screen.dart';
import 'zmanim_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AlarmProvider>().loadAlarms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(now: _now),
            _PermissionBanner(),
            _NextZmanBanner(),
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              indicatorWeight: 2,
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Theme.of(context).appSubtle,
              tabs: [
                Tab(text: l10n.tabAlarms),
                Tab(text: l10n.tabZmanim),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AlarmList(),
                  ZmanimScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAlarmScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.newAlarm),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime now;

  const _Header({required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = DateFormat('EEEE d MMMM yyyy', l10n.dateLocale).format(now);
    final hebrewDate = HebrewDateService.fromGregorian(now);

    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.appHeaderGradient,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: t.appText,
                        fontSize: 36,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(color: t.appMid, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: t.appSubtle, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hebrewDate.formatted,
                      style: TextStyle(color: t.appMid, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: t.appSubtle),
                    const SizedBox(width: 4),
                    Text(
                      settings.location.name.isEmpty
                          ? '${settings.location.latitude.toStringAsFixed(2)}°, ${settings.location.longitude.toStringAsFixed(2)}°'
                          : settings.location.name,
                      style: TextStyle(color: t.appSubtle, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: Icon(Icons.settings_outlined, color: t.appMid, size: 22),
          ),
        ],
      ),
    );
  }
}

class _NextZmanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    if (!settings.loaded) return const SizedBox.shrink();

    final calc = ZmanimCalculator(
      latitude: settings.location.latitude,
      longitude: settings.location.longitude,
      elevation: settings.location.elevation,
    );

    final now = DateTime.now();
    ZmanType? nextType;
    DateTime? nextTime;

    for (int d = 0; d < 2; d++) {
      final date = now.add(Duration(days: d));
      final zmanim = calc.getAllZmanim(date);
      final sorted = zmanim.entries
          .where((e) => e.value != null && e.value!.isAfter(now))
          .toList()
        ..sort((a, b) => a.value!.compareTo(b.value!));

      if (sorted.isNotEmpty) {
        nextType = sorted.first.key;
        nextTime = sorted.first.value;
        break;
      }
    }

    if (nextType == null || nextTime == null) return const SizedBox.shrink();

    final diff = nextTime.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final countdownStr = h > 0 ? '${h}h ${m}min' : '${m} min';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            nextType.color.withValues(alpha: 0.15),
            nextType.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nextType.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(nextType.icon, color: nextType.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nextZman,
                  style: TextStyle(
                    color: nextType.color.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  nextType.localizedName(settings.locale),
                  style: TextStyle(
                    color: Theme.of(context).appText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(nextTime),
                style: TextStyle(
                  color: nextType.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.inDuration(countdownStr),
                style: TextStyle(
                  color: Theme.of(context).appMid,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlarmList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlarmProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.alarms.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: provider.alarms.length,
      itemBuilder: (context, index) {
        final alarm = provider.alarms[index];
        return AlarmCard(
          alarm: alarm,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAlarmScreen(alarm: alarm),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionBanner extends StatefulWidget {
  @override
  State<_PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<_PermissionBanner> {
  bool _exactAlarmOk = true;
  bool _batteryOk = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final exact = await AlarmService.instance.canScheduleExactAlarms();
    final battery = await AlarmService.instance.isBatteryOptimizationDisabled();
    if (mounted) setState(() { _exactAlarmOk = exact; _batteryOk = battery; });
  }

  @override
  Widget build(BuildContext context) {
    if (_exactAlarmOk && _batteryOk) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () async {
        if (!_exactAlarmOk) {
          await AlarmService.instance.openExactAlarmSettings();
        } else {
          await AlarmService.instance.requestBatteryExemption();
        }
        await _check();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                !_exactAlarmOk ? l10n.exactAlarmBanner : l10n.batteryBanner,
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.orange, size: 12),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: t.appPrimaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alarm_add, color: t.colorScheme.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noAlarmsTitle,
            style: TextStyle(
              color: t.appText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noAlarmsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.appSubtle, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
