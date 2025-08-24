import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'My Budget App',
      'setting': 'Setting',
      'theme': 'Theme',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'english': 'English',
      'burmese': 'Burmese',
    },
    'my': {
      'title': 'ငွေပမာဏ အက်ပလီကေးရှင်း',
      'setting': 'ဆက်တင်',
      'theme': 'အရောင်အလှ',
      'system': 'စနစ် ကိုအသုံးပြုပါ',
      'light': 'ဖြူ',
      'dark': 'မှောင်',
      'language': 'ဘာသာစကား',
      'english': 'အင်္ဂလိပ်',
      'burmese': 'မြန်မာ',
    }
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'my'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
