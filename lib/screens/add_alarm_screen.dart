import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../models/alarm_sound.dart';
import '../models/zman_type.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';
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
    final noExt = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return noExt
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _showZmanBottomSheet() async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsProvider>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).appCard,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ZmanSheet(
        selected: _selectedZman,
        locale: settings.locale,
        calculationMethod: settings.calculationMethod,
        l10n: l10n,
        onChanged: (z) {
          setState(() => _selectedZman = z);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _showSoundBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).appCard,
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
    final l10n = AppLocalizations.of(context);
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
          SnackBar(content: Text(l10n.audioFileError)),
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
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectAtLeastOneDay)),
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
      final locale = context.read<SettingsProvider>().locale;
      if (widget.alarm == null) {
        await provider.addAlarm(alarm, locale: locale);
      } else {
        await provider.updateAlarm(alarm, locale: locale);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.read<SettingsProvider>().locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? l10n.newAlarm : l10n.editAlarm),
        actions: [
          if (widget.alarm != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final t2 = Theme.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: t2.appCard,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text(l10n.deleteTitle,
                        style: TextStyle(color: t2.appText)),
                    content: Text(l10n.deleteConfirm(widget.alarm!.name),
                        style: TextStyle(color: t2.appMid)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancel)),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.delete,
                              style: const TextStyle(color: Colors.red))),
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
            _NameHeader(controller: _nameCtrl, l10n: l10n),
            const SizedBox(height: 28),
            _Section(
              title: l10n.sectionZman,
              child: _ZmanButton(
                selected: _selectedZman,
                locale: locale,
                onTap: _showZmanBottomSheet,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.sectionOffset,
              child: _OffsetEditor(
                isBefore: _offsetBefore,
                hours: _offsetHours,
                minutes: _offsetMins,
                l10n: l10n,
                onBeforeChanged: (v) => setState(() => _offsetBefore = v),
                onHoursChanged: (v) => setState(() => _offsetHours = v),
                onMinutesChanged: (v) => setState(() => _offsetMins = v),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.sectionDays,
              child: _DaySelector(
                selected: _daysOfWeek,
                l10n: l10n,
                onChanged: (days) => setState(() => _daysOfWeek = days),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.sectionRingtone,
              child: _SoundButton(
                soundType: _sound,
                soundPath: _customSoundPath,
                customSoundName: _customSoundName,
                onTap: _showSoundBottomSheet,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.sectionDuration,
              child: _DurationEditor(
                minutes: _ringMinutes,
                seconds: _ringSeconds,
                l10n: l10n,
                onMinutesChanged: (v) => setState(() => _ringMinutes = v),
                onSecondsChanged: (v) => setState(() => _ringSeconds = v),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.sectionOptions,
              child: Column(
                children: [
                  _OptionTile(
                    icon: Icons.vibration,
                    title: l10n.vibration,
                    trailing: Switch(
                      value: _vibrate,
                      onChanged: (v) => setState(() => _vibrate = v),
                    ),
                  ),
                  _OptionTile(
                    icon: Icons.snooze,
                    title: l10n.snooze,
                    trailing: Builder(builder: (context) {
                    final t2 = Theme.of(context);
                    return DropdownButton<int>(
                      value: _snoozeDuration,
                      dropdownColor: t2.appCard,
                      style: TextStyle(color: t2.appText),
                      underline: const SizedBox(),
                      items: [0, 5, 10, 15, 20].map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            v == 0 ? l10n.disabled : '$v min',
                            style: TextStyle(color: t2.appText),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _snoozeDuration = v ?? 5),
                    );
                  }),
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
                      widget.alarm == null ? l10n.createAlarm : l10n.save,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String label;
    if (soundPath == null) {
      label = l10n.chooseRingtone;
    } else if (soundType == AlarmSound.custom) {
      label = customSoundName ?? soundPath!.split('/').last;
    } else {
      label = _AddAlarmScreenState._formatSoundName(soundPath!);
    }

    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: t.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasSelection ? t.colorScheme.primary : t.appBorder,
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
              color: _hasSelection ? t.colorScheme.primary : t.appSubtle,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _hasSelection ? t.appText : t.appSubtle,
                  fontSize: 14,
                  fontWeight:
                      _hasSelection ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: t.appSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Sound Bottom Sheet ───────────────────────────────────────────────────────

class _SoundSheet extends StatefulWidget {
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
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingPath;
  StreamSubscription<void>? _completeSub;

  @override
  void dispose() {
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _listenForCompletion(String path) {
    _completeSub?.cancel();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted && _playingPath == path) {
        setState(() => _playingPath = null);
      }
    });
  }

  Future<void> _togglePreview(String assetPath) async {
    if (_playingPath == assetPath) {
      await _player.stop();
      setState(() => _playingPath = null);
      return;
    }
    await _player.stop();
    setState(() => _playingPath = assetPath);
    final src = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    await _player.play(AssetSource(src));
    _listenForCompletion(assetPath);
  }

  Future<void> _toggleCustomPreview(String filePath) async {
    if (_playingPath == filePath) {
      await _player.stop();
      setState(() => _playingPath = null);
      return;
    }
    await _player.stop();
    setState(() => _playingPath = filePath);
    await _player.play(DeviceFileSource(filePath));
    _listenForCompletion(filePath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(builder: (context) {
              final t = Theme.of(context);
              return Column(children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.appBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ringtoneSheetTitle,
                        style: TextStyle(
                          color: t.appMid,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.bundledPaths.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(l10n.loading,
                                style: TextStyle(color: t.appSubtle)),
                          ),
                        )
                      else
                        ...widget.bundledPaths.map((path) => _SheetRow(
                              name: _AddAlarmScreenState._formatSoundName(path),
                              isSelected:
                                  !widget.isCustom && widget.selectedPath == path,
                              isPlaying: _playingPath == path,
                              onTap: () => widget.onSelectBundled(path),
                              onPlayTap: () => _togglePreview(path),
                            )),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(l10n.or,
                                style: TextStyle(
                                    color: t.appSubtle, fontSize: 11)),
                          ),
                          const Expanded(child: Divider()),
                        ]),
                      ),
                      GestureDetector(
                        onTap: widget.onPickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.isCustom
                                ? AppTheme.gold.withValues(alpha: 0.08)
                                : t.appDeep,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isCustom
                                  ? AppTheme.gold.withValues(alpha: 0.6)
                                  : t.appBorder,
                              width: widget.isCustom ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.isCustom && widget.customSoundName != null
                                    ? Icons.audio_file
                                    : Icons.folder_open_outlined,
                                color: widget.isCustom
                                    ? AppTheme.gold
                                    : t.appSubtle,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isCustom &&
                                              widget.customSoundName != null
                                          ? widget.customSoundName!
                                          : l10n.chooseFromPhone,
                                      style: TextStyle(
                                        color: widget.isCustom
                                            ? t.appText
                                            : t.appMid,
                                        fontWeight: widget.isCustom
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      l10n.audioFormats,
                                      style: TextStyle(
                                          color: t.appSubtle, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.isCustom &&
                                  widget.customSoundName != null) ...[
                                GestureDetector(
                                  onTap: () {
                                    if (widget.selectedPath != null) {
                                      _toggleCustomPreview(widget.selectedPath!);
                                    }
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _playingPath == widget.selectedPath
                                          ? AppTheme.gold.withValues(alpha: 0.2)
                                          : t.appBorder,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _playingPath == widget.selectedPath
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: _playingPath == widget.selectedPath
                                          ? AppTheme.gold
                                          : t.appSubtle,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.check_circle,
                                    color: AppTheme.gold, size: 18),
                              ] else
                                Icon(Icons.chevron_right,
                                    color: t.appSubtle, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;

  const _SheetRow({
    required this.name,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? t.colorScheme.primary.withValues(alpha: 0.1)
              : t.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? t.colorScheme.primary : t.appBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.music_note,
                color: isSelected ? t.colorScheme.primary : t.appSubtle,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? t.appText : t.appMid,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: onPlayTap,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? t.colorScheme.primary.withValues(alpha: 0.2)
                      : t.appDeep,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPlaying ? t.colorScheme.primary : t.appBorder,
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isPlaying ? t.colorScheme.primary : t.appSubtle,
                  size: 18,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: t.colorScheme.primary, size: 18),
            ],
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
  final AppLocalizations l10n;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  const _DurationEditor({
    required this.minutes,
    required this.seconds,
    required this.l10n,
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
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.appBorder),
      ),
      child: Column(
        children: [
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
                    ? t.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isUnlimited ? t.colorScheme.primary : t.appBorder,
                  width: _isUnlimited ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.all_inclusive,
                      size: 16,
                      color: _isUnlimited ? t.colorScheme.primary : t.appSubtle),
                  const SizedBox(width: 8),
                  Text(
                    l10n.untilDismissed,
                    style: TextStyle(
                      color: _isUnlimited ? t.colorScheme.primary : t.appSubtle,
                      fontWeight:
                          _isUnlimited ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                label: l10n.minutesLabel,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: t.appText,
                    fontSize: 32,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
              _NumberPicker(
                label: l10n.secondsLabel,
                value: seconds,
                min: 0,
                max: 59,
                onChanged: onSecondsChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.gold.withValues(alpha: 0.15)
                        : t.appChipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppTheme.gold : t.appBorder,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: TextStyle(
                      color: isActive ? AppTheme.gold : t.appMid,
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
                ? l10n.ringContinues
                : l10n.ringDurationText(minutes, seconds),
            style: TextStyle(color: t.appMid, fontSize: 12),
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
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: t.appMid,
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

// ─── Name Header ─────────────────────────────────────────────────────────────

class _NameHeader extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;

  const _NameHeader({required this.controller, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.alarmNameLabel,
          style: TextStyle(
            color: t.appSubtle,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: t.appText,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          decoration: InputDecoration(
            hintText: l10n.alarmNameHint,
            hintStyle: TextStyle(
              color: t.appText.withValues(alpha: 0.2),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: t.appBorder, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: t.colorScheme.primary, width: 1.5),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
            ),
            contentPadding: const EdgeInsets.only(bottom: 8),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? l10n.alarmNameRequired : null,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

// ─── Zman Button ──────────────────────────────────────────────────────────────

class _ZmanButton extends StatelessWidget {
  final ZmanType selected;
  final String locale;
  final VoidCallback onTap;

  const _ZmanButton({
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected.color.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(selected.icon, color: selected.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.hebrewName,
                    style: TextStyle(
                      color: selected.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.localizedName(locale),
                    style: TextStyle(
                      color: Theme.of(context).appMid,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more,
                color: selected.color.withValues(alpha: 0.6), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Zman Bottom Sheet ────────────────────────────────────────────────────────

class _ZmanSheet extends StatelessWidget {
  final ZmanType selected;
  final String locale;
  final String calculationMethod;
  final AppLocalizations l10n;
  final ValueChanged<ZmanType> onChanged;

  const _ZmanSheet({
    required this.selected,
    required this.locale,
    required this.calculationMethod,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            final t = Theme.of(context);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.appBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Text(
                      l10n.chooseZman,
                      style: TextStyle(
                        color: t.appMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: t.appSubtle, size: 20),
                    ),
                  ],
                ),
              ),
            ]);
          }),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ZmanCategory.values.map((cat) {
                  final zmanim = ZmanType.values
                      .where((z) => z.category == cat)
                      .toList();
                  final catName = switch (cat) {
                    ZmanCategory.morning => l10n.morning,
                    ZmanCategory.afternoon => l10n.afternoon,
                    ZmanCategory.evening => l10n.evening,
                    ZmanCategory.night => l10n.night,
                  };
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 16, bottom: 8, left: 2),
                        child: Builder(builder: (context) => Text(
                          catName.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).appSubtle,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        )),
                      ),
                      ...zmanim.map((z) => _ZmanSheetRow(
                            zman: z,
                            locale: locale,
                            calculationMethod: calculationMethod,
                            isSelected: z == selected,
                            onTap: () => onChanged(z),
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZmanSheetRow extends StatelessWidget {
  final ZmanType zman;
  final String locale;
  final String calculationMethod;
  final bool isSelected;
  final VoidCallback onTap;

  const _ZmanSheetRow({
    required this.zman,
    required this.locale,
    required this.calculationMethod,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final methodKey = zman.calculationMethodKey;
    final isPreferred = zman.isPreferredMethod(calculationMethod);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? zman.color.withValues(alpha: 0.1)
              : t.appDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? zman.color.withValues(alpha: 0.5)
                : t.appBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(zman.icon,
                color: isSelected ? zman.color : t.appSubtle,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          zman.hebrewName,
                          style: TextStyle(
                            color: isSelected ? zman.color : t.appText,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (methodKey != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isPreferred
                                ? zman.color.withValues(alpha: 0.15)
                                : t.appChipBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isPreferred
                                  ? zman.color.withValues(alpha: 0.5)
                                  : t.appBorder,
                            ),
                          ),
                          child: Text(
                            methodKey,
                            style: TextStyle(
                              color: isPreferred ? zman.color : t.appSubtle,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isPreferred) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.star,
                              size: 11,
                              color: zman.color.withValues(alpha: 0.6)),
                        ],
                      ],
                    ],
                  ),
                  Text(
                    zman.localizedName(locale),
                    style: TextStyle(color: t.appSubtle, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: zman.color, size: 18),
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
  final AppLocalizations l10n;
  final ValueChanged<bool> onBeforeChanged;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;

  const _OffsetEditor({
    required this.isBefore,
    required this.hours,
    required this.minutes,
    required this.l10n,
    required this.onBeforeChanged,
    required this.onHoursChanged,
    required this.onMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.appBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ToggleButton(
                  label: l10n.before,
                  selected: isBefore,
                  onTap: () => onBeforeChanged(true)),
              const SizedBox(width: 12),
              _ToggleButton(
                  label: l10n.after,
                  selected: !isBefore,
                  onTap: () => onBeforeChanged(false)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                label: l10n.hoursLabel,
                value: hours,
                min: 0,
                max: 5,
                onChanged: onHoursChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(':',
                    style: TextStyle(
                        color: t.appText,
                        fontSize: 32,
                        fontWeight: FontWeight.w200)),
              ),
              _NumberPicker(
                label: l10n.minutesLabel,
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
                ? l10n.exactlyAtZman
                : l10n.offsetText(hours, minutes, isBefore),
            style: TextStyle(color: t.appMid, fontSize: 13),
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
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).appBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).appSubtle,
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
            style: TextStyle(
                color: Theme.of(context).appSubtle, fontSize: 11)),
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
                style: TextStyle(
                  color: Theme.of(context).appText,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
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

class _CircleBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleBtn({required this.icon, this.onTap});

  @override
  State<_CircleBtn> createState() => _CircleBtnState();
}

class _CircleBtnState extends State<_CircleBtn> {
  Timer? _repeatTimer;

  void _startRepeating() {
    widget.onTap?.call();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      widget.onTap?.call();
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onTap != null ? _startRepeating : null,
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: widget.onTap != null
              ? Theme.of(context).appPrimaryContainer
              : Theme.of(context).appPrimaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).appBorder),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: widget.onTap != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).appPastZman,
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selected;
  final AppLocalizations l10n;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({
    required this.selected,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final letters = l10n.dayLetters;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            const dayOrder = [7, 1, 2, 3, 4, 5, 6]; // ISO: dim en premier
            final day = dayOrder[i];
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
              child: Builder(builder: (context) {
                final t = Theme.of(context);
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.colorScheme.primary.withValues(alpha: 0.2)
                        : t.appCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? t.colorScheme.primary : t.appBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letters[i],
                      style: TextStyle(
                        color: isSelected
                            ? t.colorScheme.primary
                            : t.appSubtle,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuickSelectBtn(
                label: l10n.all,
                onTap: () => onChanged([1, 2, 3, 4, 5, 6, 7])),
            const SizedBox(width: 8),
            _QuickSelectBtn(
                label: l10n.weekdays, onTap: () => onChanged([1, 2, 3, 4, 5])),
            const SizedBox(width: 8),
            _QuickSelectBtn(
                label: l10n.weekend, onTap: () => onChanged([6, 7])),
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
          color: Theme.of(context).appChipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).appBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).appMid, fontSize: 12)),
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
    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Text(title, style: TextStyle(color: t.appText))),
          trailing,
        ],
      ),
    );
  }
}
