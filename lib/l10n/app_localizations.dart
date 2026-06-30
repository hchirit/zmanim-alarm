import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final String locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('he'),
  ];

  String _t(String fr, String en, String he) {
    switch (locale) {
      case 'en':
        return en;
      case 'he':
        return he;
      default:
        return fr;
    }
  }

  String get dateLocale =>
      locale == 'he' ? 'he' : locale == 'en' ? 'en_US' : 'fr_FR';

  // ── Général ─────────────────────────────────────────────────────────────────
  String get cancel => _t('Annuler', 'Cancel', 'ביטול');
  String get delete => _t('Supprimer', 'Delete', 'מחק');
  String get save => _t('Enregistrer', 'Save', 'שמור');

  // ── Écran principal ──────────────────────────────────────────────────────────
  String get tabAlarms => _t('Mes Alarmes', 'My Alarms', 'האזעקות שלי');
  String get tabZmanim =>
      _t('Zmanim du Jour', "Today's Zmanim", 'זמנים היום');
  String get newAlarm => _t('Nouvelle alarme', 'New alarm', 'אזעקה חדשה');
  String get nextZman => _t('Prochain Zman', 'Next Zman', 'הזמן הבא');
  String inDuration(String str) =>
      _t('dans $str', 'in $str', 'בעוד $str');
  String get noAlarmsTitle =>
      _t('Aucune alarme configurée', 'No alarms configured', 'אין אזעקות מוגדרות');
  String get noAlarmsSubtitle => _t(
    'Appuyez sur + pour créer votre première\nalarme basée sur un Zman',
    'Tap + to create your first\nZman-based alarm',
    'לחץ + ליצירת האזעקה הראשונה\nהמבוססת על זמן',
  );
  String get exactAlarmBanner => _t(
    'Autoriser les alarmes exactes pour que les alarmes sonnent à l\'heure — Appuyez pour activer',
    'Allow exact alarms so they ring on time — Tap to enable',
    'אפשר אזעקות מדויקות כדי שיצלצלו בזמן — לחץ להפעלה',
  );
  String get batteryBanner => _t(
    'Désactiver l\'optimisation batterie pour ne pas manquer d\'alarmes — Appuyez pour activer',
    'Disable battery optimization to not miss alarms — Tap to enable',
    'בטל אופטימיזציית סוללה כדי לא לפספס אזעקות — לחץ להפעלה',
  );

  // ── Carte d'alarme ───────────────────────────────────────────────────────────
  String get inactive => _t('Inactif', 'Inactive', 'לא פעיל');
  String get deleteAlarmTitle =>
      _t('Supprimer l\'alarme', 'Delete alarm', 'מחק אזעקה');
  String deleteAlarmConfirm(String name) =>
      _t('Supprimer "$name" ?', 'Delete "$name"?', 'מחק "$name"?');
  String get testTooltip => _t('Tester', 'Test', 'בדוק');
  String get testingRing =>
      _t('Sonnerie dans 5 secondes…', 'Ring in 5 seconds…', 'מצלצל בעוד 5 שניות…');
  String testingRingWithDuration(String dur) => _t(
    'Sonnerie dans 5 secondes… (s\'arrête après $dur)',
    'Ring in 5 seconds… (stops after $dur)',
    'מצלצל בעוד 5 שניות… (מפסיק אחרי $dur)',
  );
  String alarmDeleted(String name) =>
      _t('"$name" supprimée', '"$name" deleted', '"$name" נמחקה');
  String inDaysHours(int d, int h) =>
      _t('Dans ${d}j ${h}h', 'In ${d}d ${h}h', 'בעוד $d י $h ש\'');
  String inHoursMinutes(int h, int m) =>
      _t('Dans ${h}h ${m}min', 'In ${h}h ${m}min', 'בעוד $h ש\' $m ד\'');
  String inMinutes(int m) =>
      _t('Dans $m min', 'In $m min', 'בעוד $m ד\'');

  // ── Modèle alarme ────────────────────────────────────────────────────────────
  String get exactly => _t('Exactement', 'Exactly', 'בדיוק');
  String get everyDay => _t('Tous les jours', 'Every day', 'כל יום');
  String get untilDismissed =>
      _t("Jusqu'à désactivation", 'Until dismissed', 'עד כיבוי');

  List<String> get dayNames => locale == 'he'
      ? ['שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת', 'ראשון']
      : locale == 'en'
          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  List<String> get dayLetters => locale == 'he'
      ? ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש']
      : locale == 'en'
          ? ['S', 'M', 'T', 'W', 'T', 'F', 'S']
          : ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

  // ── Écran ajout alarme ───────────────────────────────────────────────────────
  String get editAlarm => _t('Modifier l\'alarme', 'Edit alarm', 'ערוך אזעקה');
  String get deleteTitle => _t('Supprimer', 'Delete', 'מחק');
  String deleteConfirm(String name) =>
      _t('Supprimer "$name" ?', 'Delete "$name"?', 'מחק "$name"?');
  String get alarmNameLabel =>
      _t('NOM DU RÉVEIL', 'ALARM NAME', 'שם האזעקה');
  String get alarmNameHint => _t(
      'Ex: Avant Netz HaChamah', 'E.g.: Before Netz HaChamah', 'לדוגמה: לפני הנץ החמה');
  String get alarmNameRequired =>
      _t('Nom requis', 'Name required', 'שם נדרש');
  String get sectionZman => _t('Zman', 'Zman', 'זמן');
  String get sectionOffset => _t('Décalage', 'Offset', 'הפרש');
  String get before => _t('Avant', 'Before', 'לפני');
  String get after => _t('Après', 'After', 'אחרי');
  String get hoursLabel => _t('Heures', 'Hours', 'שעות');
  String get minutesLabel => _t('Minutes', 'Minutes', 'דקות');
  String get exactlyAtZman =>
      _t('Exactement au Zman', 'Exactly at Zman', 'בדיוק בזמן');

  String offsetText(int h, int m, bool isBefore) {
    final dir = isBefore ? _t('avant', 'before', 'לפני') : _t('après', 'after', 'אחרי');
    if (locale == 'he') {
      final hPart = h > 0 ? '${h}ש\' ' : '';
      final mPart = m > 0 ? '${m}ד\' ' : '';
      return '$hPart${mPart}$dir הזמן';
    }
    final hPart = h > 0 ? '${h}h ' : '';
    final mPart = m > 0 ? '${m}min ' : '';
    final suffix = locale == 'en' ? 'Zman' : 'le Zman';
    return '$hPart$mPart$dir $suffix';
  }

  String get sectionDays => _t('Jours', 'Days', 'ימים');
  String get all => _t('Tous', 'All', 'הכל');
  String get weekdays => _t('Semaine', 'Weekdays', 'שבוע');
  String get weekend => _t('Week-end', 'Weekend', 'סוף שבוע');
  String get sectionRingtone => _t('Sonnerie', 'Ringtone', 'צלצול');
  String get sectionDuration =>
      _t('Durée de la sonnerie', 'Ring duration', 'משך הצלצול');
  String get sectionOptions => _t('Options', 'Options', 'אפשרויות');
  String get vibration => _t('Vibration', 'Vibration', 'רטט');
  String get snooze => _t('Snooze', 'Snooze', 'נודניק');
  String get disabled => _t('Désactivé', 'Disabled', 'מבוטל');
  String get chooseRingtone =>
      _t('Choisir sa sonnerie', 'Choose ringtone', 'בחר צלצול');
  String get ringtoneSheetTitle => _t('SONNERIE', 'RINGTONE', 'צלצול');
  String get loading => _t('Chargement…', 'Loading…', 'טוען…');
  String get or => _t('ou', 'or', 'או');
  String get chooseFromPhone =>
      _t('Choisir depuis mon téléphone…', 'Choose from my phone…', 'בחר מהטלפון…');
  String get audioFormats => _t(
    'MP3, OGG, WAV — depuis votre appareil',
    'MP3, OGG, WAV — from your device',
    'MP3, OGG, WAV — מהמכשיר שלך',
  );
  String get secondsLabel => _t('Secondes', 'Seconds', 'שניות');
  String get ringContinues => _t(
    'La sonnerie continue jusqu\'à ce que vous l\'arrêtiez',
    'Ring continues until you stop it',
    'הצלצול ממשיך עד שתעצור אותו',
  );

  String ringDurationText(int m, int s) {
    if (locale == 'he') {
      final mPart = m > 0 ? '$m ד\' ' : '';
      final sPart = s > 0 ? '$s ש\'' : '';
      return 'הצלצול יימשך $mPart$sPart';
    }
    final mPart = m > 0 ? '$m min ' : '';
    final sPart = s > 0 ? '$s sec' : '';
    return locale == 'en'
        ? 'Ring will last $mPart$sPart'
        : 'La sonnerie durera $mPart$sPart';
  }

  String get chooseZman => _t('CHOISIR UN ZMAN', 'CHOOSE A ZMAN', 'בחר זמן');
  String get morning => _t('Matin', 'Morning', 'בוקר');
  String get afternoon => _t('Après-midi', 'Afternoon', 'אחר הצהריים');
  String get evening => _t('Soir', 'Evening', 'ערב');
  String get night => _t('Nuit', 'Night', 'לילה');
  String get createAlarm =>
      _t("Créer l'alarme", 'Create alarm', 'צור אזעקה');
  String get audioFileError => _t(
    'Impossible de lire ce fichier audio',
    'Cannot read this audio file',
    'לא ניתן לקרוא קובץ זה',
  );
  String get selectAtLeastOneDay => _t(
    'Sélectionnez au moins un jour',
    'Select at least one day',
    'בחר לפחות יום אחד',
  );

  // ── Paramètres ───────────────────────────────────────────────────────────────
  String get settingsTitle => _t('Paramètres', 'Settings', 'הגדרות');
  String get sectionLocation => _t('Localisation', 'Location', 'מיקום');
  String get autoGPS => _t('GPS automatique', 'Automatic GPS', 'GPS אוטומטי');
  String get autoGPSSubtitle => _t(
    'Utiliser la position GPS du téléphone',
    'Use phone GPS position',
    'השתמש במיקום GPS של הטלפון',
  );
  String get currentPosition =>
      _t('Position actuelle', 'Current position', 'מיקום נוכחי');
  String get manualPosition =>
      _t('Position manuelle', 'Manual position', 'מיקום ידני');
  String get latitudeLabel => _t('Latitude', 'Latitude', 'קו רוחב');
  String get longitudeLabel => _t('Longitude', 'Longitude', 'קו אורך');
  String get placeName =>
      _t('Nom du lieu (optionnel)', 'Place name (optional)', 'שם המקום (אופציונלי)');
  String get savePosition =>
      _t('Enregistrer la position', 'Save position', 'שמור מיקום');
  String get presetCities =>
      _t('Villes prédéfinies', 'Preset cities', 'ערים מוגדרות');
  String get sectionCalculation =>
      _t('Méthode de calcul', 'Calculation method', 'שיטת חישוב');
  String get graSubtitle => _t(
    'Heures proportionnelles entre lever et coucher du soleil',
    'Proportional hours between sunrise and sunset',
    'שעות יחסיות בין הנץ לשקיעה',
  );
  String get mgaSubtitle => _t(
    'Heures proportionnelles entre Alot et Tzait (72 min)',
    'Proportional hours between Alot and Tzait (72 min)',
    'שעות יחסיות בין עלות לצאת (72 ד\')',
  );
  String get sectionAbout => _t('À propos', 'About', 'אודות');
  String get aboutDescription => _t(
    'Calculs astronomiques basés sur l\'algorithme USNO (Jean Meeus). Zmanim selon les opinions GRA et MGA.',
    'Astronomical calculations based on the USNO algorithm (Jean Meeus). Zmanim according to GRA and MGA opinions.',
    'חישובים אסטרונומיים על בסיס אלגוריתם USNO (ז\'אן מאוס). זמנים לפי שיטות הגר"א והמג"א.',
  );
  String get invalidCoords =>
      _t('Coordonnées invalides', 'Invalid coordinates', 'קואורדינטות לא תקינות');
  String get positionSaved =>
      _t('Position enregistrée', 'Position saved', 'מיקום נשמר');
  String get sectionLanguage => _t('Langue', 'Language', 'שפה');
  String get langFrench => _t('Français', 'French', 'צרפתית');
  String get langEnglish => _t('English', 'English', 'אנגלית');
  String get langHebrew => _t('עברית', 'Hebrew', 'עברית');

  // ── Apparence ────────────────────────────────────────────────────────────────
  String get sectionAppearance => _t('Apparence', 'Appearance', 'מראה');
  String get darkModeLabel => _t('Mode sombre', 'Dark mode', 'מצב לילה');
  String get darkModeSubtitle => _t(
    'Interface sombre pour les environnements peu éclairés',
    'Dark interface for low-light environments',
    'ממשק כהה לסביבות חשוכות',
  );

  // ── Écran Zmanim ─────────────────────────────────────────────────────────────
  String get today => _t("Aujourd'hui", 'Today', 'היום');
  String get next => _t('Suivant', 'Next', 'הבא');

  // ── Onboarding ───────────────────────────────────────────────────────────────
  String get onboardingWelcomeTitle => _t(
    'Bienvenue dans\nAlarmes Zmanim',
    'Welcome to\nZmanim Alarms',
    'ברוכים הבאים\nלאזעקות זמנים',
  );
  String get onboardingWelcomeBody => _t(
    'Cette application déclenche des alarmes aux heures liturgiques juives (zmanim). Pour fonctionner correctement, elle nécessite votre autorisation pour trois fonctionnalités essentielles.',
    'This app triggers alarms at Jewish prayer times (zmanim). To work properly, it needs your permission for three essential features.',
    'אפליקציה זו מפעילה אזעקות בזמני התפילה היהודיים (זמנים). כדי לפעול כראוי, היא זקוקה לאישורך לשלוש תכונות חיוניות.',
  );
  String get onboardingWelcomeBtn =>
      _t('Commencer', 'Get started', 'בואו נתחיל');

  String get onboardingNotifTitle =>
      _t('Notifications', 'Notifications', 'התראות');
  String get onboardingNotifBody => _t(
    'Les alarmes s\'affichent sous forme de notifications sur votre écran. Sans cette autorisation, vous ne serez pas alerté à l\'heure des prières.',
    'Alarms appear as notifications on your screen. Without this permission, you won\'t be alerted at prayer times.',
    'אזעקות מוצגות כהתראות על המסך. ללא הרשאה זו, לא תקבל התראה בזמני התפילה.',
  );
  String get onboardingNotifBtn =>
      _t('Activer les notifications', 'Enable notifications', 'אפשר התראות');

  String get onboardingAlarmTitle =>
      _t('Alarmes précises', 'Precise alarms', 'אזעקות מדויקות');
  String get onboardingAlarmBody => _t(
    'Android doit pouvoir déclencher vos alarmes à l\'heure exacte des zmanim, même lorsque le téléphone est en veille depuis longtemps. Sans cette autorisation, les alarmes peuvent sonner en retard.',
    'Android must be able to trigger your alarms at the exact zmanim time, even when the phone has been asleep for a long time. Without this, alarms may ring late.',
    'אנדרואיד צריך להיות מסוגל להפעיל את האזעקות בזמן המדויק של הזמנים, גם כשהטלפון ישן זמן רב. ללא הרשאה זו, האזעקות עלולות לצלצל באיחור.',
  );
  String get onboardingAlarmBtn => _t(
    'Autoriser les alarmes précises',
    'Allow precise alarms',
    'אפשר אזעקות מדויקות',
  );

  String get onboardingBatteryTitle =>
      _t('Fonctionnement en arrière-plan', 'Background operation', 'פעולה ברקע');
  String get onboardingBatteryBody => _t(
    'Sur Xiaomi, Samsung et d\'autres appareils, le système peut fermer l\'application pour économiser la batterie — empêchant vos alarmes de sonner. Désactivez cette restriction pour garantir un réveil fiable.',
    'On Xiaomi, Samsung, and other devices, the system may kill the app to save battery — preventing your alarms from ringing. Disable this restriction to ensure reliable wake-ups.',
    'במכשירי שיאומי, סמסונג ואחרים, המערכת עלולה לסגור את האפליקציה לחיסכון בסוללה — ולמנוע מהאזעקות לצלצל. בטל הגבלה זו להבטחת אזעקות אמינות.',
  );
  String get onboardingBatteryBtn =>
      _t('Désactiver les restrictions', 'Disable restrictions', 'בטל הגבלות');

  String get onboardingDoneTitle =>
      _t('Tout est prêt !', 'All set!', 'הכל מוכן!');
  String get onboardingDoneBody => _t(
    'Vos alarmes zmanim sont prêtes à fonctionner. Vous pouvez modifier ces autorisations à tout moment dans les paramètres de votre téléphone.',
    'Your zmanim alarms are ready to go. You can change these permissions at any time in your phone\'s settings.',
    'אזעקות הזמנים שלך מוכנות לפעולה. ניתן לשנות הרשאות אלו בכל עת בהגדרות הטלפון.',
  );
  String get onboardingDoneBtn => _t('Commencer', 'Start', 'התחל');

  String get onboardingStepOf =>
      _t('Étape', 'Step', 'שלב'); // usage: "Étape 1 / 3"
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en', 'he'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
