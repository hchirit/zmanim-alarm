# Alarmes Zmanim — זמנים

Application Android pour gérer des alarmes basées sur les heures juives (Zmanim).

## Fonctionnalités

- **16 Zmanim** : Alot HaShachar, Misheyakir, Netz HaChamah, Sof Zman Shma (GRA/MGA), Sof Zman Tefilla (GRA/MGA), Chatzot, Mincha Gedola/Ketana, Plag HaMincha, Shkiah, Tzait (3 étoiles / 42 min / Rabbenu Tam), Chatzot HaLayla
- **Décalage personnalisé** : alarme X minutes/heures avant ou après n'importe quel Zman
- **Jours configurables** : sélection libre des jours de la semaine
- **GPS automatique** ou position manuelle (avec villes prédéfinies)
- **Deux méthodes de calcul** : GRA (Vilna Gaon) et MGA (Magen Avraham)
- **Design nocturne** thème astronomique
- **Countdown** vers le prochain Zman du jour

## Prérequis

1. **Flutter SDK** ≥ 3.1 — [flutter.dev/get-started/install](https://flutter.dev/get-started/install)
2. **Android SDK** avec API 21+ (Android 5.0+)
3. Téléphone Android avec **mode développeur et débogage USB activés**

## Installation

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Lancer sur un appareil connecté / émulateur
flutter run

# 3. Ou construire l'APK de release
flutter build apk --release
# L'APK se trouve dans: build/app/outputs/flutter-apk/app-release.apk
```

## Permissions requises

Au premier lancement, l'app demande :
- **Notifications** — pour afficher les alarmes
- **Alarmes exactes** — pour déclencher les alarmes à l'heure précise (Android 12+)
  - Si refusée : aller dans Paramètres → Applications → Alarmes Zmanim → Alarmes et rappels
- **Localisation** — pour calculer les Zmanim selon votre position (optionnel)

## Architecture

```
lib/
├── main.dart                     # Point d'entrée
├── theme/app_theme.dart          # Thème sombre astronomique
├── models/
│   ├── zman_type.dart            # Énumération des 16 Zmanim + métadonnées
│   └── alarm.dart                # Modèle d'alarme
├── services/
│   ├── zmanim_calculator.dart    # Calculs astronomiques (algo USNO/Meeus)
│   ├── alarm_service.dart        # Planification des notifications
│   ├── database_service.dart     # Persistance SQLite
│   └── location_service.dart     # GPS et positions sauvegardées
├── providers/
│   ├── alarm_provider.dart       # État des alarmes
│   └── settings_provider.dart    # Paramètres
└── screens/
    ├── home_screen.dart          # Écran principal (alarmes + zmanim)
    ├── add_alarm_screen.dart     # Créer / modifier une alarme
    ├── zmanim_screen.dart        # Zmanim du jour avec navigation par date
    └── settings_screen.dart      # Localisation et méthode de calcul
```

## Calculs astronomiques

Les Zmanim sont calculés selon l'algorithme USNO (US Naval Observatory), basé sur Jean Meeus "Astronomical Algorithms". Les Shaot Zmaniyot (heures proportionnelles) suivent :
- **GRA** : du lever au coucher du soleil ÷ 12
- **MGA** : d'Alot HaShachar à Tzait HaKochavim (72 min) ÷ 12

## Villes prédéfinies

Jérusalem · Paris · Londres · New York · Tel Aviv · Anvers · Vienne · Madrid
