@echo off
echo ============================================
echo  Zmanim Alarm - Setup initial
echo ============================================
echo.

REM Vérifier que Flutter est installé
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: Flutter n'est pas installe ou pas dans le PATH.
    echo Installez Flutter depuis: https://flutter.dev/get-started/install
    pause
    exit /b 1
)

echo [1/4] Création du projet Flutter temporaire pour les icônes...
flutter create --org=com.zmanimalarm --project-name=zmanim_alarm _temp_setup >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: La création du projet temporaire a échoué.
    pause
    exit /b 1
)

echo [2/4] Copie des ressources Android générées...
if not exist "android\app\src\main\res\mipmap-hdpi" (
    xcopy "_temp_setup\android\app\src\main\res" "android\app\src\main\res" /e /i /q /y >nul
)
if exist "_temp_setup\android\gradle\wrapper\gradle-wrapper.jar" (
    copy "_temp_setup\android\gradle\wrapper\gradle-wrapper.jar" "android\gradle\wrapper\" /y >nul
)

echo [3/4] Suppression du projet temporaire...
rd /s /q "_temp_setup" >nul 2>&1

echo [4/4] Installation des dépendances Flutter...
flutter pub get
if %errorlevel% neq 0 (
    echo ERREUR: flutter pub get a échoué.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Setup terminé avec succès !
echo ============================================
echo.
echo Pour lancer l'application:
echo   flutter run
echo.
echo Pour construire l'APK:
echo   flutter build apk --release
echo   APK: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
