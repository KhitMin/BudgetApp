import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/summary_card.dart';

class MonthlyReportView extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, double> monthlyCategoryExpenses;
  final Map<String, double> plannedAmounts;
  final Map<String, double> actualAmounts;
  final String currencySymbol;
  final double currentMonthIncome;
  final double previousMonthIncome;
  final double previousMonthExpenses;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthlyReportView({
    super.key,
    required this.selectedDate,
    required this.monthlyCategoryExpenses,
    required this.plannedAmounts,
    required this.actualAmounts,
    required this.currencySymbol,
    required this.currentMonthIncome,
    required this.previousMonthIncome,
    required this.previousMonthExpenses,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView> {
  int _touchedIndex = -1;

  final List<Color> _pieChartColors = const [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        _buildDateNavigator(
          display: DateFormat.yMMMM(loc.locale.languageCode).format(widget.selectedDate),
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildSummarySection(context),
              const SizedBox(height: 24),
              _buildPieChartCard(context),
              const Divider(height: 40),
              _buildPlanningVsActualCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentMonthExpenses = widget.monthlyCategoryExpenses.values.fold(0.0, (a, b) => a + b);
    final currentRemaining = widget.currentMonthIncome - currentMonthExpenses;
    final previousRemaining = widget.previousMonthIncome - widget.previousMonthExpenses;

    return Column(
      children: [
        SummaryCard(
          icon: Icons.arrow_upward,
          iconBgColor: Colors.green.withOpacity(0.1),
          iconColor: Colors.green,
          title: loc.t('income'),
          currentAmount: widget.currentMonthIncome,
          previousAmount: widget.previousMonthIncome,
          currencySymbol: widget.currencySymbol,
          previousPeriodLabel: loc.t('lastMonth'),
        ),
        const SizedBox(height: 12),
        SummaryCard(
          icon: Icons.arrow_downward,
          iconBgColor: Colors.red.withOpacity(0.1),
          iconColor: Colors.red,
          title: loc.t('expenses'),
          currentAmount: currentMonthExpenses,
          previousAmount: widget.previousMonthExpenses,
          currencySymbol: widget.currencySymbol,
          previousPeriodLabel: loc.t('lastMonth'),
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
          previousPeriodLabel: loc.t('lastMonth'),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('reportMonthlyExpensesByCategory'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(height: 250, child: _buildPieChart(context, widget.monthlyCategoryExpenses)),
            _buildLegend(widget.monthlyCategoryExpenses, widget.currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningVsActualCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('reportPlanningVsActual'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildBarChartLegend(context),
            const SizedBox(height: 20),
            SizedBox(height: 300, child: _buildBarChart(context, widget.currencySymbol)),
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

  Widget _buildBarChartLegend(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [Container(width: 16, height: 16, color: Colors.blue.shade300), const SizedBox(width: 8), Text(loc.t('reportPlanned'))]),
        const SizedBox(width: 24),
        Row(children: [Container(width: 16, height: 16, color: Colors.red.shade300), const SizedBox(width: 8), Text(loc.t('reportActual'))]),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, String currencySymbol) {
    final loc = AppLocalizations.of(context);
    final allCategories = {...widget.plannedAmounts, ...widget.actualAmounts}.keys.toList();
    if (allCategories.isEmpty) return Center(child: Text(loc.t('reportNoData')));

    double maxY = 0;
    for (var category in allCategories) {
        final planned = widget.plannedAmounts[category] ?? 0;
        final actual = widget.actualAmounts[category] ?? 0;
        if (planned > maxY) maxY = planned;
        if (actual > maxY) maxY = actual;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 1000 : maxY * 1.2,
        barGroups: List.generate(allCategories.length, (index) {
          final category = allCategories[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: widget.plannedAmounts[category] ?? 0, color: Colors.blue.shade300, width: 15, borderRadius: BorderRadius.zero),
              BarChartRodData(toY: widget.actualAmounts[category] ?? 0, color: Colors.red.shade300, width: 15, borderRadius: BorderRadius.zero),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
            final index = value.toInt();
            if (index >= 0 && index < allCategories.length) {
              return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(allCategories[index], style: const TextStyle(fontSize: 10)));
            }
            return const Text('');
          }, reservedSize: 38)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) => Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = rodIndex == 0 ? loc.t('reportPlanned') : loc.t('reportActual');
              return BarTooltipItem(
                '$label\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(rod.toY),
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}