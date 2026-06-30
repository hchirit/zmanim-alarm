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
    final t = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: l10n.sectionAppearance),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: l10n.darkModeLabel,
          subtitle: l10n.darkModeSubtitle,
          trailing: Switch(
            value: settings.darkMode,
            onChanged: (v) => settings.setDarkMode(v),
          ),
        ),
        const SizedBox(height: 24),
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
                    icon: Icon(Icons.refresh, color: t.colorScheme.primary),
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
                    prefixIcon: Icon(Icons.north, color: t.appMid),
                  ),
                  style: TextStyle(color: t.appText),
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
                    prefixIcon: Icon(Icons.east, color: t.appMid),
                  ),
                  style: TextStyle(color: t.appText),
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
              prefixIcon: Icon(Icons.place_outlined, color: t.appMid),
            ),
            style: TextStyle(color: t.appText),
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
        Builder(builder: (context) {
          final t2 = Theme.of(context);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t2.appCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t2.appBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alarmes Zmanim v1.0',
                  style: TextStyle(
                    color: t2.appText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.aboutDescription,
                  style: TextStyle(color: t2.appSubtle, fontSize: 13),
                ),
              ],
            ),
          );
        }),
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
      style: TextStyle(
        color: Theme.of(context).appMid,
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
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.appBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: t.appMid, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: t.appText)),
                Text(subtitle,
                    style: TextStyle(color: t.appSubtle, fontSize: 12)),
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
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? t.colorScheme.primary.withValues(alpha: 0.1)
              : t.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? t.colorScheme.primary.withValues(alpha: 0.4)
                : t.appBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_city,
              color: isSelected ? t.colorScheme.primary : t.appSubtle,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                location.name,
                style: TextStyle(
                  color: isSelected ? t.appText : t.appMid,
                  fontWeight:
                      isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              '${location.latitude.toStringAsFixed(2)}°, ${location.longitude.toStringAsFixed(2)}°',
              style: TextStyle(color: t.appSubtle, fontSize: 12),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, color: t.colorScheme.primary, size: 16),
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
    final t = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? t.colorScheme.primary.withValues(alpha: 0.08)
              : t.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? t.colorScheme.primary.withValues(alpha: 0.4)
                : t.appBorder,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => v != null ? onChanged(v) : null,
              fillColor: WidgetStateProperty.all(
                  selected ? t.colorScheme.primary : t.appSubtle),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: selected ? t.appText : t.appMid,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                  Text(subtitle,
                      style: TextStyle(color: t.appSubtle, fontSize: 12)),
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
    final t = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? t.colorScheme.secondary.withValues(alpha: 0.08)
              : t.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? t.colorScheme.secondary.withValues(alpha: 0.5)
                : t.appBorder,
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
                  color: selected ? t.appText : t.appMid,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: t.colorScheme.secondary, size: 18),
          ],
        ),
      ),
    );
  }
}
