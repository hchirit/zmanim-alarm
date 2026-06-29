#!/bin/bash
echo "============================================"
echo " Zmanim Alarm - Setup initial"
echo "============================================"
echo

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "ERREUR: Flutter n'est pas installé ou pas dans le PATH."
    echo "Installez Flutter depuis: https://flutter.dev/get-started/install"
    exit 1
fi

echo "[1/4] Création du projet Flutter temporaire pour les icônes..."
flutter create --org=com.zmanimalarm --project-name=zmanim_alarm _temp_setup > /dev/null 2>&1

echo "[2/4] Copie des ressources Android générées..."
if [ ! -d "android/app/src/main/res/mipmap-hdpi" ]; then
    cp -r _temp_setup/android/app/src/main/res/mipmap-* android/app/src/main/res/ 2>/dev/null || true
fi
cp _temp_setup/android/gradle/wrapper/gradle-wrapper.jar android/gradle/wrapper/ 2>/dev/null || true

echo "[3/4] Suppression du projet temporaire..."
rm -rf _temp_setup

echo "[4/4] Installation des dépendances Flutter..."
flutter pub get

echo
echo "============================================"
echo " Setup terminé avec succès !"
echo "============================================"
echo
echo "Pour lancer l'application:"
echo "  flutter run"
echo
echo "Pour construire l'APK:"
echo "  flutter build apk --release"
