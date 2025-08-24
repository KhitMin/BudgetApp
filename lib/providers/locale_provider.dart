import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale;
  final SharedPreferences prefs;

  LocaleProvider(this.prefs) : _locale = const Locale('en') {
    _loadLocale();
  }

  Locale get locale => _locale;

  void _loadLocale() {
    final String? code = prefs.getString('locale');
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }
}
