import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'providers/alarm_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/alarm_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/alarm_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('he', null);

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
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Provider.of<SettingsProvider>(context).darkMode;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? const Color(0xFF071018) : const Color(0xFFF5F7FA),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final locale = Locale(settings.loaded ? settings.locale : 'fr');
    final themeMode = settings.darkMode ? ThemeMode.dark : ThemeMode.light;

    return ValueListenableBuilder<ActiveRingInfo?>(
      valueListenable: AlarmService.activeRing,
      builder: (context, ring, child) {
        if (ring != null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AlarmScreen(settings: ring.settings, alarm: ring.alarm),
          );
        }
        return child!;
      },
      child: MaterialApp(
        title: 'Zmanim Alarm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _AppStartup(),
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
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AlarmService.instance.initialize();

    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadFuture;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!onboardingDone) {
      if (mounted) setState(() => _showOnboarding = true);
      return;
    }

    await _finishStartup();
  }

  Future<void> _finishStartup() async {
    final alarmProvider = context.read<AlarmProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    await alarmProvider.loadAlarms();
    await alarmProvider.rescheduleAll(locale: settingsProvider.locale);
    if (mounted) setState(() { _ready = true; _showOnboarding = false; });
    // Refresh GPS after UI is shown — évite une dialog GPS pendant l'onboarding
    if (settingsProvider.useGPS) {
      settingsProvider.refreshGPSLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _finishStartup);
    }
    return _ready ? const HomeScreen() : _buildSplash();
  }

  Widget _buildSplash() {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [t.appPrimaryContainer, t.scaffoldBackgroundColor],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: t.appBorder, width: 1.5),
              ),
              child: Icon(Icons.star, color: t.colorScheme.secondary, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'Zmanim Alarm',
              style: TextStyle(
                color: t.appText,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'זמנים',
              style: TextStyle(
                color: t.colorScheme.secondary,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(t.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
