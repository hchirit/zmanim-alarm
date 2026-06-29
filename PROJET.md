# Alarmes Zmanim — Documentation du projet

Application Android Flutter pour programmer des alarmes basées sur les heures juives (Zmanim).

---

## Fonctionnalités

- **16 Zmanim** calculés astronomiquement (algorithme USNO / Jean Meeus)
- Alarme X minutes **avant ou après** n'importe quel Zman
- **4 sonneries** : Système, Classique, Douce, Shofar (fichiers WAV embarqués)
- **Durée configurable** à la seconde (de 5 sec à 59 min 59 sec, ou illimité)
- Jours de la semaine configurables, avec snooze et vibration
- Méthode de calcul **GRA ou MGA** (Shaot Zmaniyot)
- Position par **GPS** ou manuelle (8 villes prédéfinies + coordonnées libres)
- Thème sombre astronomique
- **Bouton test** sur chaque alarme (sonnerie dans 5 secondes)
- Bannière de permissions avec correction en un tap

---

## Prérequis

| Outil | Version | Emplacement |
|---|---|---|
| Flutter SDK | 3.44.2 | `C:\Users\<user>\flutter\` |
| Java (JDK) | 21 (Android Studio JBR) | `C:\Program Files\Android\Android Studio\jbr\` |
| Android SDK | API 36 | `C:\Users\<user>\AppData\Local\Android\Sdk\` |
| Android Build-Tools | 36.0.0 | *(installé automatiquement)* |
| Gradle | 9.1.0 | *(téléchargé automatiquement)* |
| AGP | 9.0.1 | *(déclaré dans settings.gradle)* |

---

## Lancer le projet

### Variables d'environnement (à définir une fois, déjà faites)

```powershell
$env:JAVA_HOME  = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "$env:USERPROFILE\AppData\Local\Android\Sdk"
# Ces chemins sont déjà dans le PATH utilisateur — aucune action requise dans un nouveau terminal
```

### Commandes

```powershell
# Se placer dans le dossier du projet
cd "C:\Zmanim Alarm"

# Lancer sur émulateur ou téléphone connecté (mode développement)
flutter run

# Compiler un APK debug
flutter build apk --debug
# → APK : build\app\outputs\flutter-apk\app-debug.apk

# Installer l'APK sur un appareil connecté (USB)
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"

# Démarrer l'émulateur
"$env:USERPROFILE\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_API_35

# Lister les appareils connectés
adb devices
```

> **Raccourci** : double-cliquer sur `run.bat` dans le dossier du projet pour lancer directement.

---

## Structure des fichiers

```
C:\Zmanim Alarm\
├── lib/                          ← Code Dart (logique de l'app)
│   ├── main.dart                 ← Point d'entrée, initialisation, permissions
│   │
│   ├── models/                   ← Structures de données
│   │   ├── alarm.dart            ← Classe Alarm (id, nom, zman, offset, jours, son, durée…)
│   │   ├── alarm_sound.dart      ← Enum AlarmSound (system/classic/gentle/shofar) + labels/icônes
│   │   └── zman_type.dart        ← Enum ZmanType (16 Zmanim) + noms hébreu/français, couleur, catégorie
│   │
│   ├── services/                 ← Logique métier
│   │   ├── zmanim_calculator.dart ← Calcul astronomique des Zmanim (algo USNO/Meeus)
│   │   ├── alarm_service.dart    ← Planification des notifications, canaux son, test alarme, permissions
│   │   ├── database_service.dart ← Persistance SQLite (v2 : colonnes sound_key + ring_duration_seconds)
│   │   └── location_service.dart ← GPS et positions prédéfinies (Jérusalem, Paris, etc.)
│   │
│   ├── providers/                ← State management (Pattern ChangeNotifier / Provider)
│   │   ├── alarm_provider.dart   ← Liste des alarmes, CRUD, reschedule
│   │   └── settings_provider.dart ← Position, méthode GRA/MGA, GPS on/off
│   │
│   ├── screens/                  ← Écrans de l'application
│   │   ├── home_screen.dart      ← Écran principal (onglets Alarmes + Zmanim du jour, bannière permissions)
│   │   ├── add_alarm_screen.dart ← Créer / modifier une alarme (Zman, décalage, jours, son, durée, options)
│   │   ├── zmanim_screen.dart    ← Tableau de tous les Zmanim du jour, navigation par date
│   │   └── settings_screen.dart  ← GPS, position manuelle, villes prédéfinies, méthode GRA/MGA
│   │
│   ├── widgets/
│   │   └── alarm_card.dart       ← Carte d'alarme (swipe supprimer, bouton ▶ test, switch on/off)
│   │
│   └── theme/
│       └── app_theme.dart        ← Thème sombre astronomique (couleurs, typographie, composants)
│
├── android/                      ← Configuration Android native
│   ├── app/
│   │   ├── build.gradle          ← Config build app (AGP 9, desugaring, Java 11, shrinkResources)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml ← Permissions (alarmes exactes, notifications, GPS, batterie…)
│   │       └── res/raw/          ← Fichiers sons embarqués
│   │           ├── alarm_classic.wav  ← Bips 880Hz répétitifs
│   │           ├── alarm_gentle.wav   ← Mélodie progressive 330→440→528Hz
│   │           └── alarm_shofar.wav   ← Corne avec harmoniques, fréquence montante
│   ├── settings.gradle           ← Plugins Gradle (AGP 9.0.1, Kotlin 2.3.20)
│   ├── build.gradle              ← Config build racine
│   └── gradle.properties         ← Options JVM, AndroidX, builtInKotlin
│
├── assets/
│   └── images/                   ← (réservé pour futures images)
│
├── pubspec.yaml                  ← Dépendances Flutter
├── run.bat                       ← Raccourci Windows : lance flutter run directement
└── PROJET.md                     ← Ce fichier
```

---

## Dépendances principales

| Package | Version | Rôle |
|---|---|---|
| `flutter_local_notifications` | ^17.0.0 | Notifications/alarmes Android avec sons personnalisés |
| `timezone` | ^0.9.4 | Calcul des heures avec fuseau horaire correct |
| `geolocator` | ^12.0.0 | Accès GPS pour la position |
| `sqflite` | ^2.3.3+1 | Base de données SQLite locale |
| `provider` | ^6.1.2 | Gestion d'état (ChangeNotifier pattern) |
| `permission_handler` | ^11.3.1 | Demande de permissions Android (batterie, alarmes…) |
| `intl` | ^0.19.0 | Formatage des dates en français |
| `shared_preferences` | ^2.3.2 | Stockage des préférences (position, méthode GRA/MGA) |

---

## Base de données SQLite

Fichier : `zmanim_alarm.db` (dans le dossier privé de l'app sur l'appareil)

**Table `alarms`** (version 2) :

| Colonne | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Identifiant auto |
| `name` | TEXT | Nom de l'alarme |
| `zman_type` | TEXT | Clé de l'enum ZmanType |
| `offset_minutes` | INTEGER | Décalage en minutes (négatif = avant) |
| `days_of_week` | TEXT | Jours séparés par virgule (ex: `1,2,5`) |
| `is_enabled` | INTEGER | 0 ou 1 |
| `snooze_duration` | INTEGER | Minutes de snooze (0 = désactivé) |
| `vibrate` | INTEGER | 0 ou 1 |
| `sound_key` | TEXT | Clé de l'enum AlarmSound (ex: `classic`) |
| `ring_duration_seconds` | INTEGER | 0 = illimité |
| `created_at` | INTEGER | Timestamp ms |

---

## Permissions Android requises

| Permission | Pourquoi |
|---|---|
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Déclencher l'alarme exactement à l'heure |
| `POST_NOTIFICATIONS` | Afficher la notification d'alarme |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Empêcher Android de tuer l'alarme en arrière-plan |
| `RECEIVE_BOOT_COMPLETED` | Reprogrammer les alarmes après redémarrage |
| `WAKE_LOCK` | Réveiller l'écran quand l'alarme sonne |
| `VIBRATE` | Vibration |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | GPS pour la position |

> **Important** : Les deux premières sont demandées au premier lancement. Si elles ne sont pas accordées, une bannière orange apparaît sur l'écran principal.

---

## Les 16 Zmanim calculés

| Catégorie | Zman | Hébreu |
|---|---|---|
| **Matin** | Aube astronomique (16.1°) | עלות השחר |
| | Misheyakir (11.5°) | משיכיר |
| | Lever du soleil | נץ החמה |
| | Fin Shma (GRA) | סוף זמן שמע גר"א |
| | Fin Shma (MGA) | סוף זמן שמע מג"א |
| | Fin Tefilla (GRA) | סוף זמן תפילה גר"א |
| | Fin Tefilla (MGA) | סוף זמן תפילה מג"א |
| | Midi halachique | חצות היום |
| **Après-midi** | Mincha Guedola | מנחה גדולה |
| | Mincha Ketana | מנחה קטנה |
| | Plag HaMincha | פלג המנחה |
| **Soir** | Coucher du soleil | שקיעה |
| | Nuit (3 étoiles, 8.5°) | צאת הכוכבים |
| | Nuit (42 min) | צאת ר"ת |
| | Nuit (Rabbenu Tam) | צאת רבנו תם |
| **Nuit** | Minuit halachique | חצות הלילה |

---

## Points techniques importants

### Gradle / Android
- AGP 9.0.1 requiert `proguard-android-optimize.txt` (pas `proguard-android.txt`)
- `coreLibraryDesugaringEnabled true` requis par `flutter_local_notifications`
- `shrinkResources false` obligatoire quand `minifyEnabled false` avec AGP 9
- Flutter migrator ajoute `android.newDsl=false` automatiquement à chaque build — comportement normal

### Notifications
- Un canal de notification distinct par sonnerie (obligatoire Android 8+)
- `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` pour les alarmes exactes
- `timeoutAfter` contrôle la durée d'affichage de la notification
- Planification sur 14 jours à l'avance

### Calcul astronomique
- Algorithme USNO (basé sur Jean Meeus, *Astronomical Algorithms*)
- Zénith 90.833° pour lever/coucher standard
- Shaot Zmaniyot : GRA = (Netz→Shkiya) ÷ 12 | MGA = (Alot→Tzait 72min) ÷ 12
