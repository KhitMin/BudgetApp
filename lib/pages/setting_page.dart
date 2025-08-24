import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(loc.t('setting'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(loc.t('theme'), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            items: [
              DropdownMenuItem(value: ThemeMode.system, child: Text(loc.t('system'))),
              DropdownMenuItem(value: ThemeMode.light, child: Text(loc.t('light'))),
              DropdownMenuItem(value: ThemeMode.dark, child: Text(loc.t('dark'))),
            ],
            onChanged: (v) {
              if (v != null) themeProvider.setThemeMode(v);
            },
          ),

          const SizedBox(height: 24),
          Text(loc.t('language'), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButton<Locale>(
            value: localeProvider.locale,
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('my'), child: Text('မြန်မာ')),
            ],
            onChanged: (l) {
              if (l != null) localeProvider.setLocale(l);
            },
          ),
        ],
      ),
    );
  }
}