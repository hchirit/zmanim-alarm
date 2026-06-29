import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../models/alarm_sound.dart';
import '../models/zman_type.dart';
import '../providers/alarm_provider.dart';
import '../theme/app_theme.dart';

class AddAlarmScreen extends StatefulWidget {
  final Alarm? alarm;

  const AddAlarmScreen({super.key, this.alarm});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late ZmanType _selectedZman;
  late int _offsetMinutes;
  late List<int> _daysOfWeek;
  late bool _vibrate;
  late int _snoozeDuration;
  late AlarmSound _sound;
  late int _ringDurationSeconds;
  String? _customSoundPath;
  String? _customSoundName;
  List<String> _bundledSoundPaths = [];
  bool _saving = false;

  Future<void> _loadBundledSounds() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest.listAssets();
    if (!mounted) return;
    setState(() {
      _bundledSoundPaths = keys
          .where((k) =>
              k.startsWith('assets/sounds/') &&
              (k.endsWith('.mp3') || k.endsWith('.wav') || k.endsWith('.ogg')))
          .toList()
        ..sort();
    });
  }

  static String _formatSoundName(String path) {
    final filename = path.split('/').last;
    if (kSoundLabels.containsKey(filename)) return kSoundLabels[filename]!;
    // Fallback auto-format pour les nouveaux fichiers non déclarés dans kSoundLabels
    final noExt = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return noExt
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String? get _soundDisplayName {
    if (_customSoundPath == null) return null;
    if (_sound == AlarmSound.custom) {
      return _customSoundName ?? _customSoundPath!.split('/').last;
    }
    return _formatSoundName(_customSoundPath!);
  }

  Future<void> _showSoundBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SoundSheet(
        bundledPaths: _bundledSoundPaths,
        selectedPath: _customSoundPath,
        isCustom: _sound == AlarmSound.custom,
        customSoundName: _customSoundName,
        onSelectBundled: (path) {
          setState(() {
            _sound = AlarmSound.bundled;
            _customSoundPath = path;
            _customSoundName = null;
          });
          Navigator.pop(ctx);
        },
        onPickFile: () async {
          Navigator.pop(ctx);
          await _pickCustomSound();
        },
      ),
    );
  }

  bool _offsetBefore = true;
  int _offsetHours = 0;
  int _offsetMins = 30;

  int _ringMinutes = 0;
  int _ringSeconds = 30;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _selectedZman = a?.zmanType ?? ZmanType.netzHachamah;
    _offsetMinutes = a?.offsetMinutes ?? -30;
    _daysOfWeek = a?.daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];
    _vibrate = a?.vibrate ?? true;
    _snoozeDuration = a?.snoozeDuration ?? 5;
    _ringDurationSeconds = a?.ringDurationSeconds ?? 30;

    if (a == null) {
      _sound = AlarmSound.bundled;
      _customSoundPath = null;
      _customSoundName = null;
    } else if (a.sound == AlarmSound.custom) {
      _sound = AlarmSound.custom;
      _customSoundPath = a.customSoundPath;
      _customSoundName = a.customSoundPath?.split('/').last;
    } else if (a.sound == AlarmSound.bundled) {
      _sound = AlarmSound.bundled;
      _customSoundPath = a.customSoundPath;
      _customSoundName = null;
    } else {
      // Ancienne alarme (classic/gentle/shofar/…) → migration vers chemin asset
      _sound = AlarmSound.bundled;
      _customSoundPath = a.sound.legacyAssetPath;
      _customSoundName = null;
    }

    _loadBundledSounds();

    final abs = _offsetMinutes.abs();
    _offsetBefore = _offsetMinutes <= 0;
    _offsetHours = abs ~/ 60;
    _offsetMins = abs % 60;

    _ringMinutes = _ringDurationSeconds ~/ 60;
    _ringSeconds = _ringDurationSeconds % 60;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomSound() async {
    try {
      const audioTypes = XTypeGroup(
        label: 'Audio',
        extensions: ['mp3', 'ogg', 'wav', 'aac', 'm4a', 'flac'],
        mimeTypes: ['audio/*'],
      );
      final xFile = await openFile(acceptedTypeGroups: [audioTypes]);
      if (xFile == null) return;

      final fileName = xFile.name;
      final ext = fileName.contains('.') ? fileName.split('.').last : 'mp3';

      // Copie dans le répertoire de l'app (gère aussi les content:// URIs)
      final appDir = await getApplicationDocumentsDirectory();
      final destPath =
          '${appDir.path}/alarm_sound_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await xFile.readAsBytes();
      await File(destPath).writeAsBytes(bytes);

      setState(() {
        _sound = AlarmSound.custom;
        _customSoundPath = destPath;
        _customSoundName = fileName;
      });

    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire ce fichier audio')),
        );
      }
    }
  }

  int get _computedOffset {
    final total = _offsetHours * 60 + _offsetMins;
    return _offsetBefore ? -total : total;
  }

  int get _computedRingDuration => _ringMinutes * 60 + _ringSeconds;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un jour')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final alarm = Alarm(
        id: widget.alarm?.id,
        name: _nameCtrl.text.trim(),
        zmanType: _selectedZman,
        offsetMinutes: _computedOffset,
        daysOfWeek: _daysOfWeek,
        vibrate: _vibrate,
        snoozeDuration: _snoozeDuration,
        sound: _sound,
        ringDurationSeconds: _computedRingDuration,
        customSoundPath: _customSoundPath,
        isEnabled: widget.alarm?.isEnabled ?? true,
      );

      final provider = context.read<AlarmProvider>();
      if (widget.alarm == null) {
        await provider.addAlarm(alarm);
      } else {
        await provider.updateAlarm(alarm);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.alarm == null ? 'Nouvelle alarme' : 'Modifier l\'alarme'),
        actions: [
          if (widget.alarm != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Supprimer',
                        style: TextStyle(color: AppTheme.onSurface)),
                    content: Text('Supprimer "${widget.alarm!.name}" ?',
                        style: const TextStyle(color: Color(0xFF8BAFC9))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Supprimer',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await context.read<AlarmProvider>().deleteAlarm(widget.alarm!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _Section(
              title: 'Nom',
              child: TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Ex: Réveil avant Netz',
                  prefixIcon:
                      Icon(Icons.label_outline, color: Color(0xFF8BAFC9)),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nom requis' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Zman',
              child: _ZmanSelector(
                selected: _selectedZman,
                onChanged: (z) => setState(() => _selectedZman = z),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Décalage',
              child: _OffsetEditor(
                isBefore: _offsetBefore,
                hours: _offsetHours,
                minutes: _offsetMins,
                onBeforeChanged: (v) => setState(() => _offsetBefore = v),
                onHoursChanged: (v) => setState(() => _offsetHours = v),
                onMinutesChanged: (v) => setState(() => _offsetMins = v),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Jours',
              child: _DaySelector(
                selected: _daysOfWeek,
                onChanged: (days) => setState(() => _daysOfWeek = days),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Sonnerie',
              child: _SoundButton(
                soundType: _sound,
                soundPath: _customSoundPath,
                customSoundName: _customSoundName,
                onTap: _showSoundBottomSheet,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Durée de la sonnerie',
              child: _DurationEditor(
                minutes: _ringMinutes,
                seconds: _ringSeconds,
                onMinutesChanged: (v) => setState(() => _ringMinutes = v),
                onSecondsChanged: (v) => setState(() => _ringSeconds = v),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Options',
              child: Column(
                children: [
                  _OptionTile(
                    icon: Icons.vibration,
                    title: 'Vibration',
                    trailing: Switch(
                      value: _vibrate,
                      onChanged: (v) => setState(() => _vibrate = v),
                    ),
                  ),
                  _OptionTile(
                    icon: Icons.snooze,
                    title: 'Snooze',
                    trailing: DropdownButton<int>(
                      value: _snoozeDuration,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(color: AppTheme.onSurface),
                      underline: const SizedBox(),
                      items: [0, 5, 10, 15, 20].map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            v == 0 ? 'Désactivé' : '$v min',
                            style: const TextStyle(color: AppTheme.onSurface),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _snoozeDuration = v ?? 5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      widget.alarm == null ? 'Créer l\'alarme' : 'Enregistrer',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sound Button ─────────────────────────────────────────────────────────────

class _SoundButton extends StatelessWidget {
  final AlarmSound soundType;
  final String? soundPath;
  final String? customSoundName;
  final VoidCallback onTap;

  const _SoundButton({
    required this.soundType,
    required this.soundPath,
    required this.customSoundName,
    required this.onTap,
  });

  bool get _hasSelection => soundPath != null;

  String get _label {
    if (soundPath == null) return 'Choisir sa sonnerie';
    if (soundType == AlarmSound.custom) {
      return customSoundName ?? soundPath!.split('/').last;
    }
    return _AddAlarmScreenState._formatSoundName(soundPath!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasSelection ? AppTheme.primaryBlue : const Color(0xFF1E3A52),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _hasSelection
                  ? (soundType == AlarmSound.custom
                      ? Icons.audio_file
                      : Icons.music_note)
                  : Icons.music_note_outlined,
              color: _hasSelection
                  ? AppTheme.primaryBlue
                  : const Color(0xFF4A6B85),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _label,
                style: TextStyle(
                  color: _hasSelection
                      ? AppTheme.onSurface
                      : const Color(0xFF4A6B85),
                  fontSize: 14,
                  fontWeight:
                      _hasSelection ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF4A6B85), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Sound Bottom Sheet ───────────────────────────────────────────────────────

class _SoundSheet extends StatelessWidget {
  final List<String> bundledPaths;
  final String? selectedPath;
  final bool isCustom;
  final String? customSoundName;
  final ValueChanged<String> onSelectBundled;
  final VoidCallback onPickFile;

  const _SoundSheet({
    required this.bundledPaths,
    required this.selectedPath,
    required this.isCustom,
    required this.customSoundName,
    required this.onSelectBundled,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A52),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SONNERIE',
                    style: TextStyle(
                      color: Color(0xFF8BAFC9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (bundledPaths.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text('Chargement…',
                            style: TextStyle(color: Color(0xFF4A6B85))),
                      ),
                    )
                  else
                    ...bundledPaths.map((path) => _SheetRow(
                          name: _AddAlarmScreenState._formatSoundName(path),
                          isSelected: !isCustom && selectedPath == path,
                          onTap: () => onSelectBundled(path),
                        )),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      const Expanded(child: Divider(color: Color(0xFF1E3A52))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Text('ou',
                            style: TextStyle(
                                color: Color(0xFF4A6B85), fontSize: 11)),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF1E3A52))),
                    ]),
                  ),
                  GestureDetector(
                    onTap: onPickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCustom
                            ? AppTheme.gold.withValues(alpha: 0.08)
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCustom
                              ? AppTheme.gold.withValues(alpha: 0.6)
                              : const Color(0xFF1E3A52),
                          width: isCustom ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCustom && customSoundName != null
                                ? Icons.audio_file
                                : Icons.folder_open_outlined,
                            color: isCustom
                                ? AppTheme.gold
                                : const Color(0xFF4A6B85),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCustom && customSoundName != null
                                      ? customSoundName!
                                      : 'Choisir depuis mon téléphone…',
                                  style: TextStyle(
                                    color: isCustom
                                        ? AppTheme.onSurface
                                        : const Color(0xFF8BAFC9),
                                    fontWeight: isCustom
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'MP3, OGG, WAV — depuis votre appareil',
                                  style: TextStyle(
                                      color: Color(0xFF4A6B85), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (isCustom)
                            const Icon(Icons.check_circle,
                                color: AppTheme.gold, size: 18)
                          else
                            const Icon(Icons.chevron_right,
                                color: Color(0xFF4A6B85), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetRow({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFF1E3A52),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.music_note,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : const Color(0xFF4A6B85),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.onSurface : const Color(0xFF8BAFC9),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Duration Editor ─────────────────────────────────────────────────────────

class _DurationEditor extends StatelessWidget {
  final int minutes;
  final int seconds;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  const _DurationEditor({
    required this.minutes,
    required this.seconds,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
  });

  static const _presets = [
    (label: '15 sec', min: 0, sec: 15),
    (label: '30 sec', min: 0, sec: 30),
    (label: '1 min', min: 1, sec: 0),
    (label: '2 min', min: 2, sec: 0),
    (label: '5 min', min: 5, sec: 0),
  ];

  bool get _isUnlimited => minutes == 0 && seconds == 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A52)),
      ),
      child: Column(
        children: [
          // Unlimited toggle
          GestureDetector(
            onTap: () {
              if (!_isUnlimited) {
                onMinutesChanged(0);
                onSecondsChanged(0);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isUnlimited
                    ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isUnlimited
                      ? AppTheme.primaryBlue
                      : const Color(0xFF1E3A52),
                  width: _isUnlimited ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.all_inclusive,
                      size: 16,
                      color: _isUnlimited
                          ? AppTheme.primaryBlue
                          : const Color(0xFF4A6B85)),
                  const SizedBox(width: 8),
                  Text(
                    "Jusqu'à désactivation",
                    style: TextStyle(
                      color: _isUnlimited
                          ? AppTheme.primaryBlue
                          : const Color(0xFF4A6B85),
                      fontWeight: _isUnlimited
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                label: 'Minutes',
                value: minutes,
                min: 0,
                max: 59,
                onChanged: (v) {
                  onMinutesChanged(v);
                  if (v > 0 && seconds == 0 && minutes == 0) {
                    onSecondsChanged(0);
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
              _NumberPicker(
                label: 'Secondes',
                value: seconds,
                min: 0,
                max: 59,
                onChanged: onSecondsChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Preset chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _presets.map((p) {
              final isActive = minutes == p.min && seconds == p.sec;
              return GestureDetector(
                onTap: () {
                  onMinutesChanged(p.min);
                  onSecondsChanged(p.sec);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.gold.withValues(alpha: 0.15)
                        : const Color(0xFF122032),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.gold
                          : const Color(0xFF1E3A52),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.gold
                          : const Color(0xFF8BAFC9),
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            _isUnlimited
                ? 'La sonnerie continue jusqu\'à ce que vous l\'arrêtiez'
                : 'La sonnerie durera ${minutes > 0 ? '${minutes} min ' : ''}${seconds > 0 ? '${seconds} sec' : ''}',
            style: const TextStyle(color: Color(0xFF8BAFC9), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF8BAFC9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ZmanSelector extends StatelessWidget {
  final ZmanType selected;
  final ValueChanged<ZmanType> onChanged;

  const _ZmanSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categories = ZmanCategory.values;

    return Column(
      children: categories.map((cat) {
        final zmanim =
            ZmanType.values.where((z) => z.category == cat).toList();
        final catName = switch (cat) {
          ZmanCategory.morning => 'Matin',
          ZmanCategory.afternoon => 'Après-midi',
          ZmanCategory.evening => 'Soir',
          ZmanCategory.night => 'Nuit',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
              child: Text(catName,
                  style: const TextStyle(
                      color: Color(0xFF4A6B85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            ...zmanim.map((z) => _ZmanOption(
                  zman: z,
                  isSelected: z == selected,
                  onTap: () => onChanged(z),
                )),
          ],
        );
      }).toList(),
    );
  }
}

class _ZmanOption extends StatelessWidget {
  final ZmanType zman;
  final bool isSelected;
  final VoidCallback onTap;

  const _ZmanOption(
      {required this.zman, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? zman.color.withValues(alpha: 0.1)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? zman.color.withValues(alpha: 0.5)
                : const Color(0xFF1E3A52),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(zman.icon,
                color: isSelected ? zman.color : const Color(0xFF4A6B85),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zman.hebrewName,
                      style: TextStyle(
                          color:
                              isSelected ? zman.color : AppTheme.onSurface,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  Text(zman.frenchName,
                      style: const TextStyle(
                          color: Color(0xFF4A6B85), fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: zman.color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OffsetEditor extends StatelessWidget {
  final bool isBefore;
  final int hours;
  final int minutes;
  final ValueChanged<bool> onBeforeChanged;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;

  const _OffsetEditor({
    required this.isBefore,
    required this.hours,
    required this.minutes,
    required this.onBeforeChanged,
    required this.onHoursChanged,
    required this.onMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A52)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ToggleButton(
                  label: 'Avant',
                  selected: isBefore,
                  onTap: () => onBeforeChanged(true)),
              const SizedBox(width: 12),
              _ToggleButton(
                  label: 'Après',
                  selected: !isBefore,
                  onTap: () => onBeforeChanged(false)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                label: 'Heures',
                value: hours,
                min: 0,
                max: 5,
                onChanged: onHoursChanged,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(':',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.w200)),
              ),
              _NumberPicker(
                label: 'Minutes',
                value: minutes,
                min: 0,
                max: 59,
                onChanged: onMinutesChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hours == 0 && minutes == 0
                ? 'Exactement au Zman'
                : '${hours > 0 ? '${hours}h ' : ''}${minutes > 0 ? '${minutes}min ' : ''}${isBefore ? 'avant' : 'après'} le Zman',
            style: const TextStyle(color: Color(0xFF8BAFC9), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : const Color(0xFF1E3A52),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppTheme.primaryBlue
                  : const Color(0xFF4A6B85),
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF4A6B85), fontSize: 11)),
        const SizedBox(height: 8),
        Row(
          children: [
            _CircleBtn(
              icon: Icons.remove,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _CircleBtn(
              icon: Icons.add,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primaryDark
              : AppTheme.primaryDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E3A52)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppTheme.primaryBlue
              : const Color(0xFF2D4A62),
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({required this.selected, required this.onChanged});

  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = selected.contains(day);
            return GestureDetector(
              onTap: () {
                final newList = List<int>.from(selected);
                if (isSelected) {
                  newList.remove(day);
                } else {
                  newList.add(day);
                  newList.sort();
                }
                onChanged(newList);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                      : AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : const Color(0xFF1E3A52),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _days[i],
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : const Color(0xFF4A6B85),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuickSelectBtn(
                label: 'Tous',
                onTap: () => onChanged([1, 2, 3, 4, 5, 6, 7])),
            const SizedBox(width: 8),
            _QuickSelectBtn(
                label: 'Semaine', onTap: () => onChanged([1, 2, 3, 4, 5])),
            const SizedBox(width: 8),
            _QuickSelectBtn(
                label: 'Week-end', onTap: () => onChanged([6, 7])),
          ],
        ),
      ],
    );
  }
}

class _QuickSelectBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSelectBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF122032),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E3A52)),
        ),
        child: Text(label,
            style: const TextStyle(color: Color(0xFF8BAFC9), fontSize: 12)),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _OptionTile(
      {required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Text(title,
                  style: const TextStyle(color: AppTheme.onSurface))),
          trailing,
        ],
      ),
    );
  }
}
