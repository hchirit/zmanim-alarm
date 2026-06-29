import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  bool _refreshing = false;
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      _latCtrl.text = settings.location.latitude.toStringAsFixed(4);
      _lonCtrl.text = settings.location.longitude.toStringAsFixed(4);
      _nameCtrl.text = settings.location.name;
    });
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l10n.sectionLocation),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.gps_fixed,
          title: l10n.autoGPS,
          subtitle: l10n.autoGPSSubtitle,
          trailing: Switch(
            value: settings.useGPS,
            onChanged: (v) => settings.setUseGPS(v),
          ),
        ),
        if (settings.useGPS) ...[
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.location_on,
            title: settings.location.name.isEmpty
                ? l10n.currentPosition
                : settings.location.name,
            subtitle:
                '${settings.location.latitude.toStringAsFixed(4)}°, ${settings.location.longitude.toStringAsFixed(4)}°',
            trailing: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                    onPressed: () async {
                      setState(() => _refreshing = true);
                      await settings.refreshGPSLocation();
                      if (mounted) setState(() => _refreshing = false);
                    },
                  ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.manualPosition),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.latitudeLabel,
                    prefixIcon: const Icon(Icons.north, color: Color(0xFF8BAFC9)),
                  ),
                  style: const TextStyle(color: AppTheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lonCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.longitudeLabel,
                    prefixIcon: const Icon(Icons.east, color: Color(0xFF8BAFC9)),
                  ),
                  style: const TextStyle(color: AppTheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l10n.placeName,
              prefixIcon:
                  const Icon(Icons.place_outlined, color: Color(0xFF8BAFC9)),
            ),
            style: const TextStyle(color: AppTheme.onSurface),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              final lat = double.tryParse(_latCtrl.text);
              final lon = double.tryParse(_lonCtrl.text);
              if (lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.invalidCoords)),
                );
                return;
              }
              settings.setManualLocation(LocationData(
                latitude: lat,
                longitude: lon,
                name: _nameCtrl.text.trim(),
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.positionSaved)),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.savePosition),
          ),
          const SizedBox(height: 12),
          _SectionHeader(title: l10n.presetCities),
          const SizedBox(height: 8),
          ...[
            LocationData.jerusalem,
            LocationData.paris,
            const LocationData(
                latitude: 51.5074, longitude: -0.1278, name: 'London'),
            const LocationData(
                latitude: 40.7128, longitude: -74.0060, name: 'New York'),
            const LocationData(
                latitude: 32.0853, longitude: 34.7818, name: 'Tel Aviv'),
            const LocationData(
                latitude: 51.2217, longitude: 4.4024, name: 'Antwerp'),
            const LocationData(
                latitude: 48.2082, longitude: 16.3738, name: 'Vienna'),
            const LocationData(
                latitude: 40.4168, longitude: -3.7038, name: 'Madrid'),
          ].map((loc) => _CityTile(
                location: loc,
                isSelected: settings.location.name == loc.name,
                onTap: () {
                  _latCtrl.text = loc.latitude.toStringAsFixed(4);
                  _lonCtrl.text = loc.longitude.toStringAsFixed(4);
                  _nameCtrl.text = loc.name;
                  settings.setManualLocation(loc);
                },
              )),
        ],
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.sectionCalculation),
        const SizedBox(height: 8),
        _MethodTile(
          title: 'GRA (Vilna Gaon)',
          subtitle: l10n.graSubtitle,
          value: 'GRA',
          groupValue: settings.calculationMethod,
          onChanged: settings.setCalculationMethod,
        ),
        const SizedBox(height: 6),
        _MethodTile(
          title: 'MGA (Magen Avraham)',
          subtitle: l10n.mgaSubtitle,
          value: 'MGA',
          groupValue: settings.calculationMethod,
          onChanged: settings.setCalculationMethod,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.sectionLanguage),
        const SizedBox(height: 8),
        _LanguageTile(
          flag: '🇫🇷',
          label: l10n.langFrench,
          value: 'fr',
          groupValue: settings.locale,
          onChanged: settings.setLocale,
        ),
        const SizedBox(height: 6),
        _LanguageTile(
          flag: '🇬🇧',
          label: l10n.langEnglish,
          value: 'en',
          groupValue: settings.locale,
          onChanged: settings.setLocale,
        ),
        const SizedBox(height: 6),
        _LanguageTile(
          flag: '🇮🇱',
          label: l10n.langHebrew,
          value: 'he',
          groupValue: settings.locale,
          onChanged: settings.setLocale,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.sectionAbout),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E3A52)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alarmes Zmanim v1.0',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.aboutDescription,
                style: const TextStyle(
                  color: Color(0xFF4A6B85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF8BAFC9),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A52)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8BAFC9), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: AppTheme.onSurface)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF4A6B85), fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  final LocationData location;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityTile(
      {required this.location,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                : const Color(0xFF1E3A52),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_city,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : const Color(0xFF4A6B85),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                location.name,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.onSurface
                      : const Color(0xFF8BAFC9),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              '${location.latitude.toStringAsFixed(2)}°, ${location.longitude.toStringAsFixed(2)}°',
              style: const TextStyle(
                  color: Color(0xFF4A6B85), fontSize: 12),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: AppTheme.primaryBlue, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                : const Color(0xFF1E3A52),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => v != null ? onChanged(v) : null,
              fillColor: WidgetStateProperty.all(
                  selected ? AppTheme.primaryBlue : const Color(0xFF4A6B85)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.onSurface
                            : const Color(0xFF8BAFC9),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF4A6B85), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String label;
  final String value;
  final String groupValue;
  final Future<void> Function(String) onChanged;

  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.gold.withValues(alpha: 0.08)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.gold.withValues(alpha: 0.5)
                : const Color(0xFF1E3A52),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.onSurface : const Color(0xFF8BAFC9),
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.gold, size: 18),
          ],
        ),
      ),
    );
  }
}
