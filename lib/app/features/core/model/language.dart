// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';

enum Language {
  english(name: 'English', flag: '🇬🇧', isoCode: 'en'),
  amharic(name: 'Amharic', localName: 'አማርኛ', flag: '🇪🇹', isoCode: 'am'),
  arabic(name: 'Arabic', localName: 'العربية', flag: '🇸🇦', isoCode: 'ar'),
  armenian(name: 'Armenian', localName: 'հայերեն', flag: '🇦🇲', isoCode: 'hy'),
  bangla(name: 'Bangla', localName: 'বাংলা', flag: '🇧🇩', isoCode: 'bn'),
  basque(name: 'Basque', localName: 'euskara', flag: '🇪🇸', isoCode: 'eu'),
  bulgarian(name: 'Bulgarian', localName: 'български', flag: '🇧🇬', isoCode: 'bg'),
  burmese(name: 'Burmese', localName: 'မြန်မာ', flag: '🇲🇲', isoCode: 'my'),
  catalan(name: 'Catalan', localName: 'català', flag: '🇪🇸', isoCode: 'ca'),
  centralKurdish(
    name: 'Central Kurdish',
    localName: 'کوردیی ناوەندی',
    flag: '🇮🇶',
    isoCode: 'ckb',
  ),
  chinese(name: 'Chinese', localName: '中文', flag: '🇨🇳', isoCode: 'zh'),
  czech(name: 'Czech', localName: 'čeština', flag: '🇨🇿', isoCode: 'cs'),
  danish(name: 'Danish', localName: 'dansk', flag: '🇩🇰', isoCode: 'da'),
  divehi(name: 'Divehi', flag: '🇲🇻', isoCode: 'dv'),
  dutch(name: 'Dutch', localName: 'Nederlands', flag: '🇳🇱', isoCode: 'nl'),
  esperanto(name: 'Esperanto', flag: '🌍', isoCode: 'eo'),
  estonian(name: 'Estonian', localName: 'eesti', flag: '🇪🇪', isoCode: 'et'),
  finnish(name: 'Finnish', localName: 'suomi', flag: '🇫🇮', isoCode: 'fi'),
  french(name: 'French', localName: 'français', flag: '🇫🇷', isoCode: 'fr'),
  georgian(name: 'Georgian', localName: 'ქართული', flag: '🇬🇪', isoCode: 'ka'),
  german(name: 'German', localName: 'Deutsch', flag: '🇩🇪', isoCode: 'de'),
  greek(name: 'Greek', localName: 'Ελληνικά', flag: '🇬🇷', isoCode: 'el'),
  gujarati(name: 'Gujarati', localName: 'ગુજરાતી', flag: '🇮🇳', isoCode: 'gu'),
  haitianCreole(name: 'Haitian Creole', flag: '🇭🇹', isoCode: 'ht'),
  hebrew(name: 'Hebrew', localName: 'עברית', flag: '🇮🇱', isoCode: 'he'),
  hindi(name: 'Hindi', localName: 'हिन्दी', flag: '🇮🇳', isoCode: 'hi'),
  hungarian(name: 'Hungarian', localName: 'magyar', flag: '🇭🇺', isoCode: 'hu'),
  icelandic(name: 'Icelandic', localName: 'íslenska', flag: '🇮🇸', isoCode: 'is'),
  indonesian(name: 'Indonesian', localName: 'Indonesia', flag: '🇮🇩', isoCode: 'id'),
  italian(name: 'Italian', localName: 'italiano', flag: '🇮🇹', isoCode: 'it'),
  japanese(name: 'Japanese', localName: '日本語', flag: '🇯🇵', isoCode: 'ja'),
  kannada(name: 'Kannada', localName: 'ಕನ್ನಡ', flag: '🇮🇳', isoCode: 'kn'),
  khmer(name: 'Khmer', localName: 'ខ្មែរ', flag: '🇰🇭', isoCode: 'km'),
  korean(name: 'Korean', localName: '한국어', flag: '🇰🇷', isoCode: 'ko'),
  lao(name: 'Lao', localName: 'ລາວ', flag: '🇱🇦', isoCode: 'lo'),
  latvian(name: 'Latvian', localName: 'latviešu', flag: '🇱🇻', isoCode: 'lv'),
  lithuanian(name: 'Lithuanian', localName: 'lietuvių', flag: '🇱🇹', isoCode: 'lt'),
  malay(name: 'Malay', localName: 'Melayu', flag: '🇲🇾', isoCode: 'ms'),
  malayalam(name: 'Malayalam', localName: 'മലയാളം', flag: '🇮🇳', isoCode: 'ml'),
  marathi(name: 'Marathi', localName: 'मराठी', flag: '🇮🇳', isoCode: 'mr'),
  nepali(name: 'Nepali', localName: 'नेपाली', flag: '🇳🇵', isoCode: 'ne'),
  norwegian(name: 'Norwegian', localName: 'norsk', flag: '🇳🇴', isoCode: 'no'),
  odia(name: 'Odia', localName: 'ଓଡ଼ିଆ', flag: '🇮🇳', isoCode: 'or'),
  pashto(name: 'Pashto', localName: 'پښتو', flag: '🇦🇫', isoCode: 'ps'),
  persian(name: 'Persian', localName: 'فارسی', flag: '🇮🇷', isoCode: 'fa'),
  polish(name: 'Polish', localName: 'polski', flag: '🇵🇱', isoCode: 'pl'),
  portuguese(name: 'Portuguese', localName: 'português', flag: '🇵🇹', isoCode: 'pt'),
  punjabi(name: 'Punjabi', localName: 'ਪੰਜਾਬੀ', flag: '🇮🇳', isoCode: 'pa'),
  romanian(name: 'Romanian', localName: 'română', flag: '🇷🇴', isoCode: 'ro'),
  russian(name: 'Russian', localName: 'русский', flag: '🇷🇺', isoCode: 'ru'),
  serbian(name: 'Serbian', localName: 'српски', flag: '🇷🇸', isoCode: 'sr'),
  sindhi(name: 'Sindhi', localName: 'سنڌي', flag: '🇵🇰', isoCode: 'sd'),
  sinhala(name: 'Sinhala', localName: 'සිංහල', flag: '🇱🇰', isoCode: 'si'),
  slovenian(name: 'Slovenian', localName: 'slovenščina', flag: '🇸🇮', isoCode: 'sl'),
  spanish(name: 'Spanish', localName: 'español', flag: '🇪🇸', isoCode: 'es'),
  swedish(name: 'Swedish', localName: 'svenska', flag: '🇸🇪', isoCode: 'sv'),
  tagalog(name: 'Tagalog', flag: '🇵🇭', isoCode: 'tl'),
  tamil(name: 'Tamil', localName: 'தமிழ்', flag: '🇮🇳', isoCode: 'ta'),
  telugu(name: 'Telugu', localName: 'తెలుగు', flag: '🇮🇳', isoCode: 'te'),
  thai(name: 'Thai', localName: 'ไทย', flag: '🇹🇭', isoCode: 'th'),
  tibetan(name: 'Tibetan', localName: 'བོད་སྐད་', flag: '🇨🇳', isoCode: 'bo'),
  turkish(name: 'Turkish', localName: 'Türkçe', flag: '🇹🇷', isoCode: 'tr'),
  ukrainian(name: 'Ukrainian', localName: 'українська', flag: '🇺🇦', isoCode: 'uk'),
  urdu(name: 'Urdu', localName: 'اردو', flag: '🇵🇰', isoCode: 'ur'),
  uyghur(name: 'Uyghur', localName: 'ئۇيغۇرچە', flag: '🇨🇳', isoCode: 'ug'),
  vietnamese(name: 'Vietnamese', localName: 'Tiếng Việt', flag: '🇻🇳', isoCode: 'vi'),
  welsh(name: 'Welsh', localName: 'Cymraeg', flag: '🏴', isoCode: 'cy');

  const Language({
    required this.name,
    required this.flag,
    required this.isoCode,
    this.localName,
  });

  final String name;
  final String flag;
  final String isoCode;
  final String? localName;

  String get displayName => name + (localName != null ? ' - $localName' : '');

  static Language? fromIsoCode(String isoCode) {
    return Language.values.firstWhereOrNull(
      (lang) => isoCode.toLowerCase() == lang.isoCode.toLowerCase(),
    );
  }
}
