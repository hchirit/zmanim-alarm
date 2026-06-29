import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/alarm_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize French locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Request permissions before runApp (pas besoin du contexte)
  await AlarmService.instance.requestNotificationPermission();
  await AlarmService.instance.requestExactAlarmPermission();
  await AlarmService.instance.requestBatteryExemption();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF071018),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ZmanimAlarmApp());
}

class ZmanimAlarmApp extends StatelessWidget {
  const ZmanimAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
      ],
      // ValueListenableBuilder ici (au-dessus de _AppStartup) pour que
      // AlarmScreen ne soit jamais recréé quand _AppStartup rebuilde.
      child: ValueListenableBuilder<ActiveRingInfo?>(
        valueListenable: AlarmService.activeRing,
        builder: (context, ring, child) {
          if (ring != null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: AlarmScreen(settings: ring.settings, alarm: ring.alarm),
            );
          }
          return child!;
        },
        child: MaterialApp(
          title: 'Alarmes Zmanim',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _AppStartup(),
        ),
      ),
    );
  }
}

class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Initialiser le service ici pour que le navigatorKey soit prêt
    // et que AlarmScreen puisse s'afficher si l'alarme sonne au démarrage.
    await AlarmService.instance.initialize();

    final settingsProvider = context.read<SettingsProvider>();
    final alarmProvider = context.read<AlarmProvider>();

    // Wait for settings to load
    await Future.delayed(const Duration(milliseconds: 100));

    if (!settingsProvider.loaded) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return !settingsProvider.loaded;
      });
    }

    // Reschedule all alarms on app start
    await alarmProvider.loadAlarms();
    await alarmProvider.rescheduleAll();

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? const HomeScreen() : _buildSplash();
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFF1A3A5C), Color(0xFF071018)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF1E3A52), width: 1.5),
              ),
              child: const Icon(Icons.star,
                  color: AppTheme.gold, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Alarmes Zmanim',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'זמנים',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
