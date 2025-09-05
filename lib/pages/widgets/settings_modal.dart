import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/currency_provider.dart';
import '../../l10n/app_localizations.dart';

/// Shows a modal bottom sheet with app settings.
Future<void> showSettingsModal(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // Set the sheet's own background to transparent
    backgroundColor: Colors.transparent, 
    builder: (BuildContext context) {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
          final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
          final loc = AppLocalizations.of(context);

          const List<String> currencyOptions = ['MMK', '\$', '₩'];
          final String currentCurrency = currencyOptions.contains(currencyProvider.currencySymbol)
              ? currencyProvider.currencySymbol
              : 'MMK';

          // This Container now provides the background color and rounded corners.
          // Since it's inside the Consumer, it will be rebuilt on theme change.
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('settingTitle'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  Text(loc.t('settingTheme'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildSettingsDropdown<ThemeMode>(
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
                  _buildSettingsDropdown<Locale>(
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
                  _buildSettingsDropdown<String>(
                    value: currentCurrency,
                    items: [
                      DropdownMenuItem(value: 'MMK', child: Text(loc.t('currencyMMK'))),
                      DropdownMenuItem(value: '\$', child: Text(loc.t('currencyUSD'))),
                      DropdownMenuItem(value: '₩', child: Text(loc.t('currencyKRW'))),
                    ],
                    onChanged: (c) {
                      if (c != null) currencyProvider.setCurrency(c);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// Helper widget to keep dropdowns consistent
Widget _buildSettingsDropdown<T>({
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return DropdownButtonFormField<T>(
    initialValue: value,
    items: items,
    onChanged: onChanged,
    isExpanded: true,
    decoration: InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}