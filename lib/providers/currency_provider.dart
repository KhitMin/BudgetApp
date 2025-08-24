import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  String _selectedCurrency = 'MMK'; // Default currency

  CurrencyProvider(this._prefs) {
    _loadCurrency();
  }

  String get currencySymbol => _selectedCurrency;

  void _loadCurrency() {
    // SharedPreferences ကနေ သိမ်းထားတဲ့ currency ကို ပြန်ယူပါ
    // မရှိသေးရင် default 'MMK' ကိုသုံးပါ
    _selectedCurrency = _prefs.getString('selectedCurrency') ?? 'MMK';
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    _selectedCurrency = newCurrency;
    // ရွေးချယ်လိုက်တဲ့ currency အသစ်ကို SharedPreferences မှာ သိမ်းဆည်းပါ
    await _prefs.setString('selectedCurrency', newCurrency);
    notifyListeners();
  }
}