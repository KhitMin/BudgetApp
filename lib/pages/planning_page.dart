import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  Map<String, List<Map<String, dynamic>>> _allIncomes = {};
  Map<String, List<Map<String, dynamic>>> _allPlans = {};
  double _totalIncome = 0.0;
  double _totalPlannedBudget = 0.0;
  double _remainingBalance = 0.0;
  DateTime _currentMonth = DateTime.now();
  late bool _isEditable;

  final TextEditingController _incomeNameController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _planValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _checkEditableStatus();
  }

  @override
  void dispose() {
    _incomeNameController.dispose();
    _incomeAmountController.dispose();
    _planNameController.dispose();
    _planValueController.dispose();
    super.dispose();
  }

  void _checkEditableStatus() {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    setState(() {
      _isEditable = !_currentMonth.isBefore(threeMonthsAgo);
    });
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final incomesString = prefs.getString('all_incomes');
    if (incomesString != null) {
      _allIncomes = Map<String, List<Map<String, dynamic>>>.from(
        (json.decode(incomesString) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
        )
      );
    }

    final plansString = prefs.getString('all_plans');
    if (plansString != null) {
      _allPlans = Map<String, List<Map<String, dynamic>>>.from(
        (json.decode(plansString) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
        )
      );
    }
    _calculateTotalIncomeAndPlans();
    if(mounted) setState(() {});
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('all_incomes', json.encode(_allIncomes));
    await prefs.setString('all_plans', json.encode(_allPlans));
  }

  void _calculateTotalIncomeAndPlans() {
    double totalIncome = 0.0;
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);

    _allIncomes.forEach((key, monthIncomes) {
      for (var income in monthIncomes) {
        if (income['isRecurring'] == true) {
          totalIncome += (income['amount'] as num).toDouble();
        }
      }
    });
    final currentMonthIncomes = _allIncomes[currentMonthKey] ?? [];
     for (var income in currentMonthIncomes) {
      if (income['isRecurring'] != true) {
        totalIncome += (income['amount'] as num).toDouble();
      }
    }

    double totalPlanned = 0.0;
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];
    for (var plan in currentMonthPlans) {
      totalPlanned += (plan['amount'] as num).toDouble();
    }

    if(mounted) {
       setState(() {
        _totalIncome = totalIncome;
        _totalPlannedBudget = totalPlanned;
        _remainingBalance = _totalIncome - _totalPlannedBudget;
      });
    }
  }

  void _showIncomeInputModal({int? index}) {
    final loc = AppLocalizations.of(context);
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
    bool isEditing = index != null;
    bool modalIsRecurring = false;
    
    if (isEditing) {
      final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
      final income = _allIncomes[currentMonthKey]![index];
      _incomeNameController.text = income['name'] as String;
      _incomeAmountController.text = income['amount'].toString();
      modalIsRecurring = income['isRecurring'] ?? false;
    } else {
      _incomeNameController.clear();
      _incomeAmountController.clear();
      modalIsRecurring = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalStateSetter) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.0, right: 16.0, top: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      isEditing ? loc.t('planningEditIncomeTitle') : loc.t('planningAddIncomeTitle'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _incomeNameController,
                      decoration: InputDecoration(labelText: loc.t('planningIncomeNameLabel'), border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _incomeAmountController,
                      decoration: InputDecoration(labelText: loc.t('planningAmountLabel', args: {'currency': currencySymbol}), border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(loc.t('planningIsRecurringLabel')),
                      value: modalIsRecurring,
                      onChanged: (bool? newValue) {
                        modalStateSetter(() { modalIsRecurring = newValue ?? false; });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_incomeNameController.text.isEmpty || _incomeAmountController.text.isEmpty) return;
                        final String monthKey = DateFormat('yyyy-MM').format(_currentMonth);
                        final incomeData = {
                          'name': _incomeNameController.text,
                          'amount': double.tryParse(_incomeAmountController.text) ?? 0.0,
                          'isRecurring': modalIsRecurring,
                        };
                        setState(() {
                          if (isEditing) {
                            _allIncomes[monthKey]![index] = incomeData;
                          } else {
                            _allIncomes.putIfAbsent(monthKey, () => []).add(incomeData);
                          }
                          _calculateTotalIncomeAndPlans();
                        });
                        _saveAllData();
                        Navigator.pop(context);
                      },
                      child: Text(isEditing ? loc.t('edit') : loc.t('save')),
                    ),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            final String monthKey = DateFormat('yyyy-MM').format(_currentMonth);
                            setState(() {
                              _allIncomes[monthKey]!.removeAt(index);
                              _calculateTotalIncomeAndPlans();
                            });
                            _saveAllData();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text(loc.t('planningDeleteIncomeBtn')),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlanInputModal({int? index}) {
    final loc = AppLocalizations.of(context);
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
    bool isEditing = index != null;
    String planType = 'fixed';
    
    if (isEditing) {
      final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
      final plan = _allPlans[currentMonthKey]![index];
      _planNameController.text = plan['name'] as String;
      planType = plan['type'] ?? 'fixed';
      _planValueController.text = plan['value'].toString();
    } else {
      _planNameController.clear();
      _planValueController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalStateSetter) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.0, right: 16.0, top: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      isEditing ? loc.t('planningEditPlanTitle') : loc.t('planningAddPlanTitle'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text(loc.t('planningAmountChip')),
                          selected: planType == 'fixed',
                          onSelected: (bool selected) {
                            if (selected) modalStateSetter(() { planType = 'fixed'; });
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: Text(loc.t('planningPercentageChip')),
                          selected: planType == 'percentage',
                          onSelected: (bool selected) {
                            if (selected) modalStateSetter(() { planType = 'percentage'; });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _planNameController,
                      decoration: InputDecoration(labelText: loc.t('planningCategoryNameLabel'), border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _planValueController,
                      decoration: InputDecoration(
                        labelText: planType == 'fixed' ? loc.t('planningValueLabel') + ' ($currencySymbol)' : loc.t('planningPercentageLabel'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_planNameController.text.isEmpty || _planValueController.text.isEmpty) return;
                        final String monthKey = DateFormat('yyyy-MM').format(_currentMonth);
                        final double value = double.tryParse(_planValueController.text) ?? 0.0;
                        double amount = (planType == 'percentage') ? (_totalIncome * value) / 100 : value;
                        final planData = {'name': _planNameController.text, 'amount': amount, 'type': planType, 'value': value};
                        setState(() {
                          if (isEditing) {
                            _allPlans[monthKey]![index] = planData;
                          } else {
                            _allPlans.putIfAbsent(monthKey, () => []).add(planData);
                          }
                          _calculateTotalIncomeAndPlans();
                        });
                        _saveAllData();
                        Navigator.pop(context);
                      },
                      child: Text(isEditing ? loc.t('edit') : loc.t('save')),
                    ),
                     if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            final String monthKey = DateFormat('yyyy-MM').format(_currentMonth);
                            setState(() {
                              _allPlans[monthKey]!.removeAt(index);
                              _calculateTotalIncomeAndPlans();
                            });
                            _saveAllData();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text(loc.t('planningDeletePlanBtn')),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    final allItems = _getAllChartItems();
    if (_totalIncome <= 0 || allItems.isEmpty) {
      return [
        PieChartSectionData(color: Colors.grey, value: 100, title: '0%', radius: 80, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ];
    }
    return allItems.map((item) {
      final double percentage = (_totalIncome > 0) ? ((item['value'] as num) / _totalIncome) * 100 : 0;
      return PieChartSectionData(
        color: item['color'] as Color,
        value: (item['value'] as num).toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
  
  List<Map<String, dynamic>> _getAllChartItems() {
    final loc = AppLocalizations.of(context);
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];
    const List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.cyan, Colors.pink, Colors.teal, Colors.indigo,
    ];
    List<Map<String, dynamic>> items = [];
    int colorIndex = 0;
    for (var plan in currentMonthPlans) {
      items.add({'name': plan['name'], 'value': plan['amount'], 'color': colors[colorIndex++ % colors.length]});
    }
    if (_remainingBalance > 0) {
      items.add({'name': loc.t('planningRemainingBalance'), 'value': _remainingBalance, 'color': Colors.teal});
    } else if (_remainingBalance < 0) {
      items.add({'name': loc.t('planningOverspending'), 'value': _remainingBalance.abs(), 'color': Colors.red});
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = currencyProvider.currencySymbol;
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final currentMonthIncomes = _allIncomes[currentMonthKey] ?? [];
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];
    final allChartItems = _getAllChartItems();
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                        _calculateTotalIncomeAndPlans();
                        _checkEditableStatus();
                      });
                    },
                  ),
                  Text(
                    DateFormat.yMMMM(loc.locale.languageCode).format(_currentMonth),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                        _calculateTotalIncomeAndPlans();
                        _checkEditableStatus();
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(loc.t('planningTotalIncome'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(_totalIncome),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text(loc.t('planningPlannedBudget'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(_totalPlannedBudget),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  Text( _remainingBalance >= 0 ? loc.t('planningRemainingBalance') : loc.t('planningOverspending'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(_remainingBalance),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _remainingBalance >= 0 ? Colors.teal : Colors.red),
                  ),
                ],
              ),
            ),
            if (_totalIncome > 0)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(height: 250, child: PieChart(PieChartData(sections: _getPieChartSections(), centerSpaceRadius: 40, sectionsSpace: 2))),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: allChartItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(width: 16, height: 16, color: item['color'] as Color),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item['name'] as String, style: const TextStyle(fontSize: 14), softWrap: true)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            )
            else 
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(loc.t('planningNoIncomePrompt'), style: const TextStyle(color: Colors.red, fontSize: 16)),
              ),
            
            const Divider(),
            
            ExpansionTile(
              title: Text(loc.t('planningIncomes')),
              initiallyExpanded: true,
              children: [
                if (currentMonthIncomes.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(loc.t('planningAddIncomePrompt'))))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentMonthIncomes.length,
                    itemBuilder: (context, index) {
                      final income = currentMonthIncomes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(income['name'] as String),
                          subtitle: Text(income['isRecurring'] == true ? loc.t('planningRecurringIncome') : loc.t('planningOneTimeIncome')),
                          trailing: Text(
                            NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(income['amount']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: _isEditable ? () => _showIncomeInputModal(index: index) : null,
                        ),
                      );
                    },
                  ),
              ],
            ),
            
            const Divider(),
            
            ExpansionTile(
              title: Text(loc.t('planningPlannedExpenses')),
              initiallyExpanded: true,
              children: [
                if (currentMonthPlans.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(loc.t('planningAddPlanPrompt'))))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentMonthPlans.length,
                    itemBuilder: (context, index) {
                      final plan = currentMonthPlans[index];
                      final amountDisplay = NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(plan['amount']);
                      final String displayValue = plan['type'] == 'percentage' ? '${plan['value']}% ($amountDisplay)' : amountDisplay;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(plan['name'] as String),
                          trailing: Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: _isEditable ? () => _showPlanInputModal(index: index) : null,
                        ),
                      );
                    },
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEditable ? _showIncomeInputModal : null,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: Text(loc.t('planningAddIncomeBtn')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEditable ? _showPlanInputModal : null,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: Text(loc.t('planningPlanExpenseBtn')),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isEditable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Text(
                  loc.t('planningEditDisabledTooltip'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
