// lib/pages/reports/widgets/summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final double currentAmount;
  final double previousAmount;
  final String currencySymbol;
  final String previousPeriodLabel;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.currentAmount,
    required this.previousAmount,
    required this.currencySymbol,
    required this.previousPeriodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // --- Calculation ---
    
    // --- Formatting ---
    final numberFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleMedium),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              numberFormat.format(currentAmount),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${loc.t('vs')} ${numberFormat.format(previousAmount)} $previousPeriodLabel',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}