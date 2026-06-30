import 'package:flutter/material.dart';

enum ZmanCategory { morning, afternoon, evening, night }

enum ZmanType {
  alotHashachar,
  misheyakir,
  netzHachamah,
  sofZmanShmaGRA,
  sofZmanShmaMGA,
  sofZmanTefillaGRA,
  sofZmanTefillaMGA,
  chatzot,
  minchaGedola,
  minchaKetana,
  plagHamincha,
  shkiah,
  tzait8_5,
  tzait42,
  tzaitRabbenuvTam,
  chatzotLayla,
}

extension ZmanTypeInfo on ZmanType {
  String get hebrewName {
    const names = {
      ZmanType.alotHashachar: 'עלות השחר',
      ZmanType.misheyakir: 'משיכיר',
      ZmanType.netzHachamah: 'הנץ החמה',
      ZmanType.sofZmanShmaGRA: 'סוף זמן ק״ש (גר״א)',
      ZmanType.sofZmanShmaMGA: 'סוף זמן ק״ש (מג״א)',
      ZmanType.sofZmanTefillaGRA: 'סוף זמן תפלה (גר״א)',
      ZmanType.sofZmanTefillaMGA: 'סוף זמן תפלה (מג״א)',
      ZmanType.chatzot: 'חצות היום',
      ZmanType.minchaGedola: 'מנחה גדולה',
      ZmanType.minchaKetana: 'מנחה קטנה',
      ZmanType.plagHamincha: 'פלג המנחה',
      ZmanType.shkiah: 'שקיעת החמה',
      ZmanType.tzait8_5: 'צאת הכוכבים',
      ZmanType.tzait42: 'צאת (42 דקות)',
      ZmanType.tzaitRabbenuvTam: 'צאת רבנו תם',
      ZmanType.chatzotLayla: 'חצות הלילה',
    };
    return names[this]!;
  }

  String get frenchName {
    const names = {
      ZmanType.alotHashachar: 'Alot HaShachar (Aube)',
      ZmanType.misheyakir: 'Misheyakir',
      ZmanType.netzHachamah: 'Netz HaChamah (Lever du soleil)',
      ZmanType.sofZmanShmaGRA: 'Sof Zman Shma (GRA)',
      ZmanType.sofZmanShmaMGA: 'Sof Zman Shma (MGA)',
      ZmanType.sofZmanTefillaGRA: 'Sof Zman Tefilla (GRA)',
      ZmanType.sofZmanTefillaMGA: 'Sof Zman Tefilla (MGA)',
      ZmanType.chatzot: 'Chatzot (Midi solaire)',
      ZmanType.minchaGedola: 'Mincha Gedola',
      ZmanType.minchaKetana: 'Mincha Ketana',
      ZmanType.plagHamincha: 'Plag HaMincha',
      ZmanType.shkiah: 'Shkiah (Coucher du soleil)',
      ZmanType.tzait8_5: 'Tzait HaKochavim (3 étoiles)',
      ZmanType.tzait42: 'Tzait (42 min après coucher)',
      ZmanType.tzaitRabbenuvTam: 'Tzait Rabbenu Tam (72 min)',
      ZmanType.chatzotLayla: 'Chatzot HaLayla (Minuit)',
    };
    return names[this]!;
  }

  String get englishName {
    const names = {
      ZmanType.alotHashachar: 'Alot HaShachar (Dawn)',
      ZmanType.misheyakir: 'Misheyakir',
      ZmanType.netzHachamah: 'Netz HaChamah (Sunrise)',
      ZmanType.sofZmanShmaGRA: 'Sof Zman Shma (GRA)',
      ZmanType.sofZmanShmaMGA: 'Sof Zman Shma (MGA)',
      ZmanType.sofZmanTefillaGRA: 'Sof Zman Tefilla (GRA)',
      ZmanType.sofZmanTefillaMGA: 'Sof Zman Tefilla (MGA)',
      ZmanType.chatzot: 'Chatzot (Solar Noon)',
      ZmanType.minchaGedola: 'Mincha Gedola',
      ZmanType.minchaKetana: 'Mincha Ketana',
      ZmanType.plagHamincha: 'Plag HaMincha',
      ZmanType.shkiah: 'Shkiah (Sunset)',
      ZmanType.tzait8_5: 'Tzait HaKochavim (3 stars)',
      ZmanType.tzait42: 'Tzait (42 min after sunset)',
      ZmanType.tzaitRabbenuvTam: 'Tzait Rabbenu Tam (72 min)',
      ZmanType.chatzotLayla: 'Chatzot HaLayla (Midnight)',
    };
    return names[this]!;
  }

  String localizedName(String locale) {
    switch (locale) {
      case 'en':
        return englishName;
      case 'he':
        return hebrewName;
      default:
        return frenchName;
    }
  }

  String get description {
    const descs = {
      ZmanType.alotHashachar: '16.1° sous l\'horizon – l\'aube astronomique',
      ZmanType.misheyakir: '11.5° sous l\'horizon – début des mitzvot du matin',
      ZmanType.netzHachamah: 'Apparition du bord supérieur du soleil',
      ZmanType.sofZmanShmaGRA: '3 heures proportionnelles (GRA) après le lever',
      ZmanType.sofZmanShmaMGA: '3 heures proportionnelles (MGA) après l\'aube',
      ZmanType.sofZmanTefillaGRA: '4 heures proportionnelles (GRA) après le lever',
      ZmanType.sofZmanTefillaMGA: '4 heures proportionnelles (MGA) après l\'aube',
      ZmanType.chatzot: 'Le soleil atteint son zénith',
      ZmanType.minchaGedola: '30 min après Chatzot',
      ZmanType.minchaKetana: '9.5 heures proportionnelles après le lever',
      ZmanType.plagHamincha: '10.75 heures proportionnelles après le lever',
      ZmanType.shkiah: 'Disparition du bord supérieur du soleil',
      ZmanType.tzait8_5: '8.5° sous l\'horizon – 3 étoiles visibles',
      ZmanType.tzait42: '42 minutes après le coucher du soleil',
      ZmanType.tzaitRabbenuvTam: '72 minutes après le coucher du soleil',
      ZmanType.chatzotLayla: 'Milieu de la nuit astronomique',
    };
    return descs[this]!;
  }

  String get _englishDescription {
    const descs = {
      ZmanType.alotHashachar: '16.1° below horizon – astronomical dawn',
      ZmanType.misheyakir: '11.5° below horizon – start of morning mitzvot',
      ZmanType.netzHachamah: 'Appearance of the upper edge of the sun',
      ZmanType.sofZmanShmaGRA: '3 proportional hours (GRA) after sunrise',
      ZmanType.sofZmanShmaMGA: '3 proportional hours (MGA) after dawn',
      ZmanType.sofZmanTefillaGRA: '4 proportional hours (GRA) after sunrise',
      ZmanType.sofZmanTefillaMGA: '4 proportional hours (MGA) after dawn',
      ZmanType.chatzot: 'The sun reaches its zenith',
      ZmanType.minchaGedola: '30 min after Chatzot',
      ZmanType.minchaKetana: '9.5 proportional hours after sunrise',
      ZmanType.plagHamincha: '10.75 proportional hours after sunrise',
      ZmanType.shkiah: 'Disappearance of the upper edge of the sun',
      ZmanType.tzait8_5: '8.5° below horizon – 3 stars visible',
      ZmanType.tzait42: '42 minutes after sunset',
      ZmanType.tzaitRabbenuvTam: '72 minutes after sunset',
      ZmanType.chatzotLayla: 'Middle of the astronomical night',
    };
    return descs[this]!;
  }

  String get _hebrewDescription {
    const descs = {
      ZmanType.alotHashachar: '16.1° מתחת לאופק – עלות השחר האסטרונומי',
      ZmanType.misheyakir: '11.5° מתחת לאופק – תחילת מצוות הבוקר',
      ZmanType.netzHachamah: 'הופעת שפת השמש העליונה',
      ZmanType.sofZmanShmaGRA: '3 שעות יחסיות (גר"א) אחרי הנץ',
      ZmanType.sofZmanShmaMGA: '3 שעות יחסיות (מג"א) אחרי עלות השחר',
      ZmanType.sofZmanTefillaGRA: '4 שעות יחסיות (גר"א) אחרי הנץ',
      ZmanType.sofZmanTefillaMGA: '4 שעות יחסיות (מג"א) אחרי עלות השחר',
      ZmanType.chatzot: 'השמש מגיעה לשיאה',
      ZmanType.minchaGedola: '30 דקות אחרי חצות',
      ZmanType.minchaKetana: '9.5 שעות יחסיות אחרי הנץ',
      ZmanType.plagHamincha: '10.75 שעות יחסיות אחרי הנץ',
      ZmanType.shkiah: 'היעלמות שפת השמש העליונה',
      ZmanType.tzait8_5: '8.5° מתחת לאופק – 3 כוכבים נראים',
      ZmanType.tzait42: '42 דקות אחרי השקיעה',
      ZmanType.tzaitRabbenuvTam: '72 דקות אחרי השקיעה',
      ZmanType.chatzotLayla: 'אמצע הלילה האסטרונומי',
    };
    return descs[this]!;
  }

  String localizedDescription(String locale) {
    switch (locale) {
      case 'en':
        return _englishDescription;
      case 'he':
        return _hebrewDescription;
      default:
        return description;
    }
  }

  ZmanCategory get category {
    const cats = {
      ZmanType.alotHashachar: ZmanCategory.morning,
      ZmanType.misheyakir: ZmanCategory.morning,
      ZmanType.netzHachamah: ZmanCategory.morning,
      ZmanType.sofZmanShmaGRA: ZmanCategory.morning,
      ZmanType.sofZmanShmaMGA: ZmanCategory.morning,
      ZmanType.sofZmanTefillaGRA: ZmanCategory.morning,
      ZmanType.sofZmanTefillaMGA: ZmanCategory.morning,
      ZmanType.chatzot: ZmanCategory.afternoon,
      ZmanType.minchaGedola: ZmanCategory.afternoon,
      ZmanType.minchaKetana: ZmanCategory.afternoon,
      ZmanType.plagHamincha: ZmanCategory.afternoon,
      ZmanType.shkiah: ZmanCategory.evening,
      ZmanType.tzait8_5: ZmanCategory.evening,
      ZmanType.tzait42: ZmanCategory.evening,
      ZmanType.tzaitRabbenuvTam: ZmanCategory.evening,
      ZmanType.chatzotLayla: ZmanCategory.night,
    };
    return cats[this]!;
  }

  Color get color {
    switch (category) {
      case ZmanCategory.morning:
        return const Color(0xFFFFAB40);
      case ZmanCategory.afternoon:
        return const Color(0xFF80DEEA);
      case ZmanCategory.evening:
        return const Color(0xFFEF9A9A);
      case ZmanCategory.night:
        return const Color(0xFFCE93D8);
    }
  }

  /// 'GRA', 'MGA', ou null si ce zman ne dépend pas de la méthode de calcul.
  String? get calculationMethodKey {
    switch (this) {
      case ZmanType.sofZmanShmaGRA:
      case ZmanType.sofZmanTefillaGRA:
        return 'GRA';
      case ZmanType.sofZmanShmaMGA:
      case ZmanType.sofZmanTefillaMGA:
        return 'MGA';
      default:
        return null;
    }
  }

  /// true si ce zman n'est pas spécifique à une méthode, ou s'il correspond
  /// à la méthode préférée de l'utilisateur.
  bool isPreferredMethod(String method) =>
      calculationMethodKey == null || calculationMethodKey == method;

  IconData get icon {
    switch (this) {
      case ZmanType.alotHashachar:
        return Icons.nights_stay;
      case ZmanType.misheyakir:
        return Icons.wb_twilight;
      case ZmanType.netzHachamah:
        return Icons.wb_sunny;
      case ZmanType.sofZmanShmaGRA:
      case ZmanType.sofZmanShmaMGA:
        return Icons.menu_book;
      case ZmanType.sofZmanTefillaGRA:
      case ZmanType.sofZmanTefillaMGA:
        return Icons.auto_stories;
      case ZmanType.chatzot:
        return Icons.brightness_high;
      case ZmanType.minchaGedola:
      case ZmanType.minchaKetana:
        return Icons.sunny;
      case ZmanType.plagHamincha:
        return Icons.wb_cloudy;
      case ZmanType.shkiah:
        return Icons.brightness_3;
      case ZmanType.tzait8_5:
      case ZmanType.tzait42:
      case ZmanType.tzaitRabbenuvTam:
        return Icons.star;
      case ZmanType.chatzotLayla:
        return Icons.bedtime;
    }
  }
}
