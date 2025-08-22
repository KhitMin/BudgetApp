// lib/pages/planning_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  double _remainingBalance = 0.0; // လက်ကျန်ငွေအတွက်
  DateTime _currentMonth = DateTime.now();
  late bool _isEditable;

  final TextEditingController _incomeNameController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();

  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _planValueController = TextEditingController(); // Amount or percentage

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
    final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);
    setState(() {
      _isEditable = _currentMonth.isAfter(twoMonthsAgo) ||
          _currentMonth.month == twoMonthsAgo.month && _currentMonth.year == twoMonthsAgo.year;
    });
  }

  void _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final incomesString = prefs.getString('all_incomes');
    if (incomesString != null) {
      try {
        final decodedData = json.decode(incomesString) as Map<String, dynamic>;
        _allIncomes = decodedData.map(
          (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
        );
      } catch (e) {
        print('Error decoding incomes data: $e');
        _allIncomes = {};
      }
    }

    final plansString = prefs.getString('all_plans');
    if (plansString != null) {
      try {
        final decodedData = json.decode(plansString) as Map<String, dynamic>;
        _allPlans = decodedData.map(
          (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
        );
      } catch (e) {
        print('Error decoding plans data: $e');
        _allPlans = {};
      }
    }
    _calculateTotalIncomeAndPlans();
    setState(() {});
  }

  void _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('all_incomes', json.encode(_allIncomes));
    await prefs.setString('all_plans', json.encode(_allPlans));
  }

  void _calculateTotalIncomeAndPlans() {
    double totalIncome = 0.0;
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);

    final currentMonthIncomes = _allIncomes[currentMonthKey] ?? [];
    for (var income in currentMonthIncomes) {
      totalIncome += income['amount'] as double;
    }
    _allIncomes.forEach((key, value) {
      if (key != currentMonthKey) {
        for (var income in value) {
          if (income['isRecurring'] == true) {
            totalIncome += income['amount'] as double;
          }
        }
      }
    });

    double totalPlanned = 0.0;
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];
    for (var plan in currentMonthPlans) {
      totalPlanned += plan['amount'] as double;
    }

    setState(() {
      _totalIncome = totalIncome;
      _totalPlannedBudget = totalPlanned;
      _remainingBalance = _totalIncome - _totalPlannedBudget; // Calculate remaining balance
    });
  }

  void _showIncomeInputModal({int? index}) {
    bool isEditing = index != null;
    bool modalIsRecurring = false;
    
    if (isEditing) {
      final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
      final income = _allIncomes[currentMonthKey]![index];
      _incomeNameController.text = income['name'] as String;
      _incomeAmountController.text = income['amount'].toString();
      modalIsRecurring = income['isRecurring'] as bool;
    } else {
      _incomeNameController.clear();
      _incomeAmountController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalStateSetter) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      isEditing ? 'အဝင်ငွေ ပြင်ဆင်ရန်' : 'အဝင်ငွေ အသစ်ထည့်ရန်',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _incomeNameController,
                      decoration: const InputDecoration(
                        labelText: 'ဝင်ငွေအမည်',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _incomeAmountController,
                      decoration: const InputDecoration(
                        labelText: 'ပမာဏ (MMK)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: modalIsRecurring,
                          onChanged: (bool? newValue) {
                            modalStateSetter(() {
                              modalIsRecurring = newValue ?? false;
                            });
                          },
                        ),
                        const Text('လစဉ် ဝင်ငွေလား'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_incomeNameController.text.isEmpty || _incomeAmountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('အချက်အလက်အားလုံး ပြည့်စုံအောင်ထည့်ပါ')),
                          );
                          return;
                        }

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
                            if (_allIncomes[monthKey] == null) {
                              _allIncomes[monthKey] = [];
                            }
                            _allIncomes[monthKey]!.add(incomeData);
                          }
                          _calculateTotalIncomeAndPlans();
                        });

                        _saveAllData();
                        Navigator.pop(context);
                      },
                      child: Text(isEditing ? 'အဝင်ငွေ ပြင်ဆင်မည်' : 'အဝင်ငွေ ထည့်မည်'),
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
                          child: const Text('အဝင်ငွေ ဖျက်မည်'),
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
    bool isEditing = index != null;
    String planType = 'fixed'; // 'fixed' or 'percentage'
    
    if (isEditing) {
      final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
      final plan = _allPlans[currentMonthKey]![index];
      _planNameController.text = plan['name'] as String;
      planType = plan['type'] ?? 'fixed';
      if (planType == 'percentage') {
        _planValueController.text = plan['value'].toString(); // Store original percentage
      } else {
        _planValueController.text = plan['amount'].toString();
      }
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      isEditing ? 'အသုံးစရိတ် Category ပြင်ဆင်ရန်' : 'အသုံးစရိတ် Category အသစ်ထည့်ရန်',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Type Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('ပမာဏ'),
                          selected: planType == 'fixed',
                          onSelected: (bool selected) {
                            if (selected) {
                              modalStateSetter(() {
                                planType = 'fixed';
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('ရာခိုင်နှုန်း'),
                          selected: planType == 'percentage',
                          onSelected: (bool selected) {
                            if (selected) {
                              modalStateSetter(() {
                                planType = 'percentage';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _planNameController,
                      decoration: const InputDecoration(
                        labelText: 'Category အမည်',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _planValueController,
                      decoration: InputDecoration(
                        labelText: planType == 'fixed' ? 'ပမာဏ (MMK)' : 'ရာခိုင်နှုန်း (%)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_planNameController.text.isEmpty || _planValueController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('အချက်အလက်အားလုံး ပြည့်စုံအောင်ထည့်ပါ')),
                          );
                          return;
                        }

                        final String monthKey = DateFormat('yyyy-MM').format(_currentMonth);
                        final double value = double.tryParse(_planValueController.text) ?? 0.0;
                        double amount;

                        if (planType == 'percentage') {
                          amount = (_totalIncome * value) / 100;
                        } else {
                          amount = value;
                        }

                        final planData = {
                          'name': _planNameController.text,
                          'amount': amount,
                          'type': planType,
                          'value': value, // store original value for editing
                        };

                        setState(() {
                          if (isEditing) {
                            _allPlans[monthKey]![index] = planData;
                          } else {
                            if (_allPlans[monthKey] == null) {
                              _allPlans[monthKey] = [];
                            }
                            _allPlans[monthKey]!.add(planData);
                          }
                          _calculateTotalIncomeAndPlans();
                        });

                        _saveAllData();
                        Navigator.pop(context);
                      },
                      child: Text(isEditing ? 'အသုံးစရိတ် ပြင်ဆင်မည်' : 'အသုံးစရိတ်ထည့်မည်'),
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
                          child: const Text('အသုံးစရိတ် ဖျက်မည်'),
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
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];

    if (_totalIncome <= 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: '0%', // Only percentage is shown
          radius: 80,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }
    
    List<PieChartSectionData> sections = [];
    final allItems = _getAllChartItems();
    
    // Create sections for all items (plans and remaining balance)
    for (var item in allItems) {
      final double percentage = (_totalIncome > 0) ? (item['value'] / _totalIncome) * 100 : 0;
      final String titleText = '${percentage.toStringAsFixed(1)}%';

      sections.add(
        PieChartSectionData(
          color: item['color'] as Color,
          value: item['value'] as double,
          title: titleText,
          radius: 80,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return sections;
  }
  
  // This function is for creating the legend data
  List<Map<String, dynamic>> _getAllChartItems() {
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];

    const List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple,
      Colors.orange, Colors.cyan, Colors.pink, Colors.teal, Colors.indigo,
    ];

    List<Map<String, dynamic>> items = [];
    int colorIndex = 0;
    
    // Add plans to the list
    for (var plan in currentMonthPlans) {
      items.add({
        'name': plan['name'],
        'value': plan['amount'],
        'color': colors[colorIndex % colors.length],
      });
      colorIndex++;
    }

    // Add remaining balance to the list
    if (_remainingBalance > 0) {
      items.add({
        'name': 'လက်ကျန်ငွေ',
        'value': _remainingBalance,
        'color': Colors.teal,
      });
    } else if (_remainingBalance < 0) {
      items.add({
        'name': 'အပိုသုံးစွဲမှု',
        'value': _remainingBalance.abs(),
        'color': Colors.red,
      });
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final currentMonthIncomes = _allIncomes[currentMonthKey] ?? [];
    final currentMonthPlans = _allPlans[currentMonthKey] ?? [];
    
    // Get all chart items for the legend
    final allChartItems = _getAllChartItems();
    
    return SingleChildScrollView(
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
                  DateFormat.yMMMM().format(_currentMonth),
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
                const Text(
                  'စုစုပေါင်း ဝင်ငွေ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_totalIncome MMK',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 20),
                const Text(
                  'စီစဉ်ထားသော အသုံးစရိတ်',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_totalPlannedBudget MMK',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                const Text(
                  'လက်ကျန်ငွေ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_remainingBalance MMK',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _remainingBalance >= 0 ? Colors.teal : Colors.red,
                  ),
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
                child: SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieChartSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
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
                            Container(
                              width: 16,
                              height: 16,
                              color: item['color'] as Color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(fontSize: 14),
                                softWrap: true, // Allow text to wrap
                              ),
                            ),
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
            const Text("ဝင်ငွေထည့်သွင်းပြီးမှ စီစဉ်နိုင်သည်", style: TextStyle(color: Colors.red)),
          
          const Divider(),
          
          ExpansionTile(
            title: const Text('ဝင်ငွေများ'),
            children: [
              if (currentMonthIncomes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('အဝင်ငွေများ ထည့်သွင်းရန်'),
                  ),
                )
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
                        subtitle: Text(
                          income['isRecurring'] == true ? 'လစဉ်ဝင်ငွေ' : 'တစ်ကြိမ်တည်း ဝင်ငွေ',
                        ),
                        trailing: Text(
                          '${income['amount']} MMK',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onLongPress: _isEditable ? () => _showIncomeInputModal(index: index) : null,
                      ),
                    );
                  },
                ),
            ],
          ),
          
          const Divider(),
          
          ExpansionTile(
            title: const Text('စီစဉ်ထားသော အသုံးစရိတ်များ'),
            children: [
              if (currentMonthPlans.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('အသုံးစရိတ်များ စီစဉ်ရန်'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentMonthPlans.length,
                  itemBuilder: (context, index) {
                    final plan = currentMonthPlans[index];
                    final String displayValue = plan['type'] == 'percentage'
                        ? '${plan['value']}% (${plan['amount']} MMK)'
                        : '${plan['amount']} MMK';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(plan['name'] as String),
                        trailing: Text(
                          displayValue,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onLongPress: _isEditable ? () => _showPlanInputModal(index: index) : null,
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
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('အဝင်ငွေ ထည့်မည်'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isEditable ? _showPlanInputModal : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('အသုံးစရိတ် စီစဉ်မည်'),
                  ),
                ),
              ],
            ),
          ),
          if (!_isEditable)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'လွန်ခဲ့သော ၂ လအထိသာ ဝင်ငွေနှင့် အသုံးစရိတ်များကို ထည့်သွင်းနိုင်သည်',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
