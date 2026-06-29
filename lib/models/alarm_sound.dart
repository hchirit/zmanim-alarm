enum AlarmSound {
  bundled, // asset path stored in customSoundPath (assets/sounds/...)
  custom,  // absolute file path stored in customSoundPath

  // Legacy values — kept only for DB backward compatibility
  system, classic, gentle, shofar, missionImpossible, pinkPanther,
}

/// Noms affichés pour chaque fichier du dossier assets/sounds/.
/// Pour renommer un son, modifie la valeur correspondante ici.
/// Les nouveaux fichiers sans entrée ici auront un nom généré automatiquement.
const Map<String, String> kSoundLabels = {
  'alarm_classic.wav': 'Classique',
  'alarm_gentle.wav': 'Douce',
  'alarm_shofar.wav': 'Shofar',
  'alarm_silence.wav': 'Silence',
  'mission_impossible.mp3': 'Mission Impossible',
  'pink_panther.mp3': 'Pink Panther',
};

extension AlarmSoundExt on AlarmSound {
  // Used only to migrate legacy DB alarms to the new bundled approach
  String get legacyAssetPath => switch (this) {
        AlarmSound.gentle => 'assets/sounds/alarm_gentle.wav',
        AlarmSound.shofar => 'assets/sounds/alarm_shofar.wav',
        AlarmSound.missionImpossible => 'assets/sounds/mission_impossible.mp3',
        AlarmSound.pinkPanther => 'assets/sounds/pink_panther.mp3',
        _ => 'assets/sounds/alarm_classic.wav',
      };
}
