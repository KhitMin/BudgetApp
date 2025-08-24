import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final loc = AppLocalizations.of(context);

    // *** အဓိက ပြင်ဆင်မှု - Dropdown အတွက် ရွေးချယ်စရာ list ကို ကြိုတင်တည်ဆောက်ပါ ***
    const List<String> currencyOptions = ['MMK', '\$', '₩']; // USD ကို $ သို့ ပြောင်းထားပါသည်
    // လက်ရှိသိမ်းထားတဲ့ चलनက ရွေးစရာထဲမှာ ရှိမရှိ စစ်ဆေးပါ
    final String currentCurrency = currencyOptions.contains(currencyProvider.currencySymbol)
        ? currencyProvider.currencySymbol
        : 'MMK'; // မရှိတော့ရင် MMK ကို default အဖြစ်သုံးပါ

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(loc.t('settingTitle'), style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 32),

            Text(loc.t('settingTheme'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButton<ThemeMode>(
              isExpanded: true,
              value: themeProvider.themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(loc.t('settingThemeSystem'))),
                DropdownMenuItem(value: ThemeMode.light, child: Text(loc.t('settingThemeLight'))),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(loc.t('settingThemeDark'))),
              ],
              onChanged: (v) {
                if (v != null) themeProvider.setThemeMode(v);
              },
            ),

            const SizedBox(height: 24),

            Text(loc.t('settingLanguage'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButton<Locale>(
              isExpanded: true,
              value: localeProvider.locale,
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('my'), child: Text('မြန်မာ')),
              ],
              onChanged: (l) {
                if (l != null) localeProvider.setLocale(l);
              },
            ),

            const SizedBox(height: 24),

            Text(loc.t('settingCurrency'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: currentCurrency, // စစ်ဆေးပြီးသား value ကိုသုံးပါ
              items: const [
                DropdownMenuItem(value: 'MMK', child: Text('Myanmar Kyat (MMK)')),
                // *** ဤနေရာတွင် USD ကို $ သို့ ပြောင်းလဲထားပါသည် ***
                DropdownMenuItem(value: '\$', child: Text('US Dollar (\$)')),
                DropdownMenuItem(value: '₩', child: Text('Korean Won (₩)')),
              ],
              onChanged: (c) {
                if (c != null) currencyProvider.setCurrency(c);
              },
            ),
          ],
        ),
      ),
    );
  }
}
