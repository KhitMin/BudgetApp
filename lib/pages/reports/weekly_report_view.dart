import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/summary_card.dart';

class WeeklyReportView extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, double> weeklyCategoryExpenses;
  final String currencySymbol;
  final double currentWeekIncome;
  final double previousWeekIncome;
  final double previousWeekExpenses;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const WeeklyReportView({
    super.key,
    required this.selectedDate,
    required this.weeklyCategoryExpenses,
    required this.currencySymbol,
    required this.currentWeekIncome,
    required this.previousWeekIncome,
    required this.previousWeekExpenses,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<WeeklyReportView> createState() => _WeeklyReportViewState();
}

class _WeeklyReportViewState extends State<WeeklyReportView> {
  int _touchedIndex = -1;

  final List<Color> _pieChartColors = const [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final startOfWeek = widget.selectedDate.subtract(Duration(days: widget.selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    String dateRangeDisplay = '${DateFormat.MMMd(loc.locale.languageCode).format(startOfWeek)} - ${DateFormat.yMMMd(loc.locale.languageCode).format(endOfWeek)}';
    
    return Column(
      children: [
        _buildDateNavigator(
          display: dateRangeDisplay,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildSummarySection(context),
              const SizedBox(height: 24),
              _buildPieChartSection(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentWeekExpenses = widget.weeklyCategoryExpenses.values.fold(0.0, (a,b) => a + b);
    final currentRemaining = widget.currentWeekIncome - currentWeekExpenses;
    final previousRemaining = widget.previousWeekIncome - widget.previousWeekExpenses;
    
    return Column(
      children: [
        SummaryCard(
          icon: Icons.arrow_upward,
          iconBgColor: Colors.green.withOpacity(0.1),
          iconColor: Colors.green,
          title: loc.t('income'),
          currentAmount: widget.currentWeekIncome,
          previousAmount: widget.previousWeekIncome,
          currencySymbol: widget.currencySymbol,
          previousPeriodLabel: loc.t('lastWeek'),
        ),
        const SizedBox(height: 12),
        SummaryCard(
          icon: Icons.arrow_downward,
          iconBgColor: Colors.red.withOpacity(0.1),
          iconColor: Colors.red,
          title: loc.t('expenses'),
          currentAmount: currentWeekExpenses,
          previousAmount: widget.previousWeekExpenses,
          currencySymbol: widget.currencySymbol,
          previousPeriodLabel: loc.t('lastWeek'),
        ),
        const SizedBox(height: 12),
         SummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          iconBgColor: Colors.blue.withOpacity(0.1),
          iconColor: Colors.blue,
          title: loc.t('remaining'),
          currentAmount: currentRemaining,
          previousAmount: previousRemaining,
          currencySymbol: widget.currencySymbol,
          previousPeriodLabel: loc.t('lastWeek'),
        ),
      ],
    );
  }
  
  Widget _buildPieChartSection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (widget.weeklyCategoryExpenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Center(child: Text(loc.t('reportNoData'), style: TextStyle(color: Colors.grey.shade600)))
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('reportWeeklyExpenseByCategory'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(height: 250, child: _buildPieChart(context, widget.weeklyCategoryExpenses)),
            const SizedBox(height: 20),
            _buildLegend(widget.weeklyCategoryExpenses, widget.currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> data) {
    if (data.isEmpty) return Center(child: Text(AppLocalizations.of(context).t('reportNoData')));
    
    final totalValue = data.values.fold(0.0, (sum, item) => sum + item);
    final dataEntries = data.entries.toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sections: List.generate(dataEntries.length, (index) {
          final isTouched = index == _touchedIndex;
          final fontSize = isTouched ? 16.0 : 12.0;
          final radius = isTouched ? 110.0 : 100.0;
          final color = _pieChartColors[index % _pieChartColors.length];
          final entry = dataEntries[index];
          final percentage = totalValue > 0 ? (entry.value / totalValue) * 100 : 0;

          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildDateNavigator({required String display, required VoidCallback onPrevious, required VoidCallback onNext}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
          Text(display, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data, String currencySymbol) {
    int colorIndex = 0;
    return Column(
      children: data.entries.map((entry) {
        final color = _pieChartColors[colorIndex++ % _pieChartColors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 14))),
              Text(
                NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(entry.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}