import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'appName': 'My Budget Planner',
      'helloMessage': 'Hello, Welcome! 👋',
      'currencyDisplayDefault': '{amount} {currency}',
      'upcomingBills': 'Upcoming Bills',
      'noUpcomingBills': 'You have no upcoming bills. ✨',
      'overdue': 'Overdue',
      'dueToday': 'Due today',
      'dueTomorrow': 'Due tomorrow',
      'dueInDays': 'Due in {days} days ({month}/{day})',
      'appTitle': 'My Budget Planner',
      'others': 'Others',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'action': 'Action',
      'confirmDelete': 'Confirm Delete',
      'confirmDeletePrompt': 'Are you sure you want to delete this item?',
      'chooseActionPrompt': 'Choose an action',
      'fillAllFields': 'Please fill all fields!',
      
      // Common
      'all': 'All',
      'income': 'Income',
      'expenses': 'Expenses',
      'expense': 'Expense',
      'allCategories': 'All Categories',
      'startDate': 'Start Date',
      'endDate': 'End Date',

      // Bottom Navigation
      'navHome': 'Home',
      'navBudget': 'Expenses',
      'navPlanning': 'Planning',
      'navReporting': 'Reporting',
      'navSetting': 'Setting',

      // Home Page
      'homeSummaryTitle': 'Summary for {month}',
      'homeIncome': 'This Month Balance',
      'homeSpent': 'Spent',
      'homeRemaining': '{percent}% remaining this month',
      'homeCurrent': 'This Month',
      'homeBalance': 'Balance',
      'homeThisMonth': 'This Month',
      'homeMonthlyOverview': 'This Month Spent / Budget',
      'homeBudgetUsed': 'Budget Used',
      'homeBudgetFormat': '{spent} / {total}',
      'homePercentBudget': '{percent}% of budget',
      'homeAddExpense': 'Add Expense',
      'homeViewReports': 'View Reports',
      'homeRecentTransactions': 'Recent Transactions',
      'homeNoTransactions': 'No transactions yet.',
      'homeTopCategories': 'Top Spending Categories',
      'homeFinancialTip': 'Tip: Review your monthly subscriptions to find potential savings!',

      // Budget Page
      'budgetTotalFor': 'Total for {month}',
      'budgetSelectDayPrompt': 'Select a day to view or add transactions',
      'budgetNoTransactionsForDay': 'No transactions for this day',
      'budgetAddTransactionTooltip': 'Add Transaction',
      'budgetCategoryLabel': 'Category: {category}',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'today': 'Today',

      // Modal Titles and Labels
      'modalAddExpense': 'Add Expense',
      'modalAddIncome': 'Add Income',
      'lunchAtSubway': 'Lunch at Subway',
      'monthlySalary': 'Monthly Salary',
      'addNewCategory': 'Add New Category',
      'categoryNameEnglish': 'Category Name (English)',
      'categoryNameEnglishHelper': 'Please enter the name in English',
      'categoryNameEnglishOnly': 'Please use English characters only',

      // Planning Page
      'planningTotalIncome': 'Total Income',
      'planningPlannedBudget': 'Planned Budget',
      'planningRemainingBalance': 'Remaining Balance',
      'planningOverspending': 'Overspending',
      'planningNoIncomePrompt': 'Add income to start planning',
      'planningIncomes': 'Incomes',
      'planningAddIncomePrompt': 'Add incomes to get started',
      'planningRecurringIncome': 'Recurring',
      'planningOneTimeIncome': 'One-time',
      'planningPlannedExpenses': 'Planned Expenses',
      'planningAddPlanPrompt': 'Add expense plans',
      'planningAddIncomeBtn': 'Add Income',
      'planningPlanExpenseBtn': 'Plan Expense',
      'planningEditDisabledTooltip': 'Can only edit plans for the last 2 months',
      'planningEditIncomeTitle': 'Edit Income',
      'planningAddIncomeTitle': 'Add New Income',
      'planningIncomeNameLabel': 'Income Name',
      'planningAmountLabel': 'Amount ({currency})',
      'planningIsRecurringLabel': 'Is this a recurring monthly income?',
      'planningDeleteIncomeBtn': 'Delete Income',
      'planningEditPlanTitle': 'Edit Expense Category',
      'planningAddPlanTitle': 'Add New Expense Category',
      'planningCategoryNameLabel': 'Category Name',
      'planningValueLabel': 'Amount',
      'planningPercentageLabel': 'Percentage (%)',
      'planningDeletePlanBtn': 'Delete Expense',
      'planningAmountChip': 'Amount',
      'planningPercentageChip': 'Percentage',

      // Reporting Page
      'reportTitle': 'Reports',
      'reportWeekly': 'Weekly Expense by Category',
      'reportMonthly': 'Monthly',
      'reportYearly': 'Yearly',
      'reportNoData': 'No data for this period.',
      'reportTotalSpend': 'Total Spend',
      'reportMonthlyExpensesByCategory': 'Monthly Expenses by Category',
      'reportPlanningVsActual': 'Planning vs Actual Spending',
      'reportYearlySummary': 'Yearly Financial Summary',
      'reportYearlyIncome': 'Total Income',
      'reportYearlyExpenses': 'Total Expenses',
      'reportYearlyExpensesByCategory': 'Expenses by Category (Yearly)',
      'reportPlanned': 'Planned',
      'reportActual': 'Actual',

      // Setting Page
      'settingTitle': 'Setting',
      'settingTheme': 'Theme',
      'settingThemeSystem': 'System',
      'settingThemeLight': 'Light',
      'settingThemeDark': 'Dark',
      'settingLanguage': 'Language',
      'settingCurrency': 'Currency',
      'currencyMMK': 'Myanmar Kyat (MMK)',
      'currencyUSD': 'US Dollar (\$)',
      'currencyKRW': 'Korean Won (₩)',

      // Expense Input Modal
      'modalEditExpense': 'Edit Expense',
      'modalAddExpenseFor': 'Add Expense for {date}',
      'modalExpenseName': 'Expense Name',
      'modalAmount': 'Amount ({currency})',
      'modalCategory': 'Category',
      'modalTimeOptional': 'Time (Optional)',
      'modalSaveChanges': 'Save Changes',
      'modalSaveExpense': 'Save Expense',
      'modalAmountLabel': 'Amount',
      'modalSave': 'Save'
    },
    'my': {
      // General
      'appName': 'ငွေကြေးစီမံသူ',
      'helloMessage': 'မင်္ဂလာပါ 👋',
      'currencyDisplayDefault': '{amount} {currency}',
      'upcomingBills': 'ပေးရန်ရှိသောငွေများ',
      'noUpcomingBills': 'ပေးရန်ရှိသောငွေ မရှိသေးပါ။ ✨',
      'overdue': 'ရက်လွန်',
      'dueToday': 'ယနေ့ပေးရန်ရှိ',
      'dueTomorrow': 'မနက်ဖြန်ပေးရန်ရှိ',
      'dueInDays': '{days} ရက်အတွင်း ပေးရန်ရှိ ({month}/{day})',
      'appTitle': 'ငွေကြေးစီမံသူ',
      'others': 'အခြား',
      'save': 'သိမ်းမည်',
      'edit': 'ပြင်မည်',
      'delete': 'ဖျက်မည်',
      'cancel': 'မလုပ်တော့ပါ',
      'action': 'လုပ်ဆောင်ချက်',
      'confirmDelete': 'ဖျက်ရန် အတည်ပြုပါ',
      'confirmDeletePrompt': 'ဤအချက်အလက်ကို ဖျက်မှာသေချာပါသလား?',
      'chooseActionPrompt': 'လုပ်ဆောင်ရန် ရွေးချယ်ပါ',
      'fillAllFields': 'အကွက်အားလုံးကို ဖြည့်စွက်ပါ!',

      // Common
      'all': 'အားလုံး',
      'income': 'ဝင်ငွေ',
      'expenses': 'သုံးစွဲငွေများ',
      'expense': 'အသုံးစရိတ်',
      'allCategories': 'ကဏ္ဍအားလုံး',
      'startDate': 'စတင်သည့်ရက်',
      'endDate': 'ပြီးဆုံးသည့်ရက်',

      // Bottom Navigation
      'navHome': 'ပင်မ',
      'navBudget': 'ထွက်ငွေ',
      'navPlanning': 'အစီအစဉ်',
      'navReporting': 'မှတ်တမ်း',
      'navSetting': 'ဆက်တင်',

      // Home Page
      'homeSummaryTitle': '{month} အတွက် အကျဉ်းချုပ်',
      'homeIncome': 'လက်ရှိလက်ကျန်ငွေ',
      'homeSpent': 'သုံးငွေ',
      'homeRemaining': 'ယခုလအတွက် {percent}% ကျန်ရှိသည်',
      'homeCurrent': 'ယခုလအတွက်',
      'homeBalance': 'လက်ကျန်ငွေ',
      'homeThisMonth': 'ယခုလအတွက်',
      'homeMonthlyOverview': 'ယခုလအတွက် သုံးစွဲမှု / ဘတ်ဂျက်',
      'homeBudgetUsed': 'သုံးစွဲပြီးသော ဘတ်ဂျက်',
      'homeBudgetFormat': '{spent} / {total}',
      'homePercentBudget': 'ဘတ်ဂျက်၏ {percent}%',
      'homeAddExpense': 'ကုန်ကျစရိတ်ထည့်မည်',
      'homeViewReports': 'မှတ်တမ်းကြည့်မည်',
      'homeRecentTransactions': 'မကြာမီက သုံးစွဲမှုများ',
      'homeNoTransactions': 'သုံးစွဲမှု မှတ်တမ်းမရှိသေးပါ',
      'homeTopCategories': 'အသုံးအများဆုံး ကဏ္ဍများ',
      'homeFinancialTip': 'အကြံပြုချက်: လစဉ်ကြေးပေးသွင်းထားသည်များကို ပြန်လည်စစ်ဆေးပြီး ငွေစုနိုင်သည်!',

      // Budget Page
      'budgetTotalFor': '{month} စုစုပေါင်း',
      'budgetSelectDayPrompt': 'ငွေစာရင်းကြည့်ရန် (သို့) ထည့်ရန် နေ့ရက်ရွေးပါ',
      'budgetNoTransactionsForDay': 'ဤနေ့အတွက် ငွေစာရင်းမှတ်တမ်းမရှိပါ',
      'budgetAddTransactionTooltip': 'ငွေစာရင်းထည့်မည်',
      'budgetCategoryLabel': 'ကဏ္ဍ: {category}',
      'thisWeek': 'ယခုအပတ်',
      'thisMonth': 'ယခုလ',
      'today': 'ယနေ့',

      // Modal Titles and Labels
      'modalAddExpense': 'အသုံးစရိတ်ထည့်ရန်',
      'modalAddIncome': 'ဝင်ငွေထည့်ရန်',
      'lunchAtSubway': 'နေ့လည်စာ',
      'monthlySalary': 'လစာ',
      'addNewCategory': 'အမျိုးအစား အသစ်ထည့်ရန်',
      'categoryNameEnglish': 'အမျိုးအစား အမည် (အင်္ဂလိပ်လိုသာ)',
      'categoryNameEnglishHelper': 'အင်္ဂလိပ်စာလုံးဖြင့်သာ ရေးပါ',
      'categoryNameEnglishOnly': 'အင်္ဂလိပ်စာလုံးဖြင့်သာ ရိုက်ထည့်ပါ',
      'selectIcon': 'သင်္ကေတ ရွေးပါ',

      // Planning Page
      'planningTotalIncome': 'စုစုပေါင်း ဝင်ငွေ',
      'planningPlannedBudget': 'စီစဉ်ထားသော အသုံးစရိတ်',
      'planningRemainingBalance': 'လက်ကျန်ငွေ',
      'planningOverspending': 'အပိုသုံးစွဲမှု',
      'planningNoIncomePrompt': 'အစီအစဉ်ဆွဲရန် ဝင်ငွေထည့်သွင်းပါ',
      'planningIncomes': 'ဝင်ငွေများ',
      'planningAddIncomePrompt': 'အဝင်ငွေများ ထည့်သွင်းရန်',
      'planningRecurringIncome': 'လစဉ်ဝင်ငွေ',
      'planningOneTimeIncome': 'တစ်ကြိမ်တည်း',
      'planningPlannedExpenses': 'စီစဉ်ထားသော အသုံးစရိတ်များ',
      'planningAddPlanPrompt': 'အသုံးစရိတ်များ စီစဉ်ရန်',
      'planningAddIncomeBtn': 'အဝင်ငွေ ထည့်မည်',
      'planningPlanExpenseBtn': 'အသုံးစရိတ် စီစဉ်မည်',
      'planningEditDisabledTooltip': 'လွန်ခဲ့သော ၂ လအထိသာ ပြင်ဆင်နိုင်သည်',
      'planningEditIncomeTitle': 'အဝင်ငွေ ပြင်ဆင်ရန်',
      'planningAddIncomeTitle': 'အဝင်ငွေ အသစ်ထည့်ရန်',
      'planningIncomeNameLabel': 'ဝင်ငွေအမည်',
      'planningAmountLabel': 'ပမာဏ ({currency})',
      'planningIsRecurringLabel': 'လစဉ် ဝင်ငွေလား',
      'planningDeleteIncomeBtn': 'အဝင်ငွေ ဖျက်မည်',
      'planningEditPlanTitle': 'အသုံးစရိတ် Category ပြင်ဆင်ရန်',
      'planningAddPlanTitle': 'အသုံးစရိတ် Category အသစ်ထည့်ရန်',
      'planningCategoryNameLabel': 'Category အမည်',
      'planningValueLabel': 'ပမာဏ',
      'planningPercentageLabel': 'ရာခိုင်နှုန်း (%)',
      'planningDeletePlanBtn': 'အသုံးစရိတ် ဖျက်မည်',
      'planningAmountChip': 'ပမာဏ',
      'planningPercentageChip': 'ရာခိုင်နှုန်း',

      // Reporting Page
      'reportTitle': 'မှတ်တမ်းများ',
      'reportWeekly': 'အပတ်စဉ်',
      'reportMonthly': 'လစဉ်',
      'reportYearly': 'နှစ်စဉ်',
      'reportNoData': 'ဤကာလအတွက် မှတ်တမ်းမရှိပါ',
      'reportTotalSpend': 'စုစုပေါင်း အသုံးစရိတ်',
      'reportMonthlyExpensesByCategory': 'လစဉ် ကုန်ကျစရိတ် (ကဏ္ဍအလိုက်)',
      'reportPlanningVsActual': 'အစီအစဉ် နှင့် အမှန်တကယ် သုံးစွဲမှု',
      'reportYearlySummary': 'နှစ်စဉ် ငွေကြေးအကျဉ်းချုပ်',
      'reportYearlyIncome': 'စုစုပေါင်း ဝင်ငွေ',
      'reportYearlyExpenses': 'စုစုပေါင်း ထွက်ငွေ',
      'reportYearlyExpensesByCategory': 'နှစ်စဉ် ကုန်ကျစရိတ် (ကဏ္ဍအလိုက်)',
      'reportPlanned': 'စီစဉ်ထား',
      'reportActual': 'အမှန်တကယ်',

      // Setting Page
      'settingTitle': 'ဆက်တင်',
      'settingTheme': 'အရောင်အသွေး',
      'settingThemeSystem': 'စနစ်အတိုင်း',
      'settingThemeLight': 'အလင်း',
      'settingThemeDark': 'အမှောင်',
      'settingLanguage': 'ဘာသာစကား',
      'settingCurrency': 'ငွေကြေး',
      'currencyMMK': 'မြန်မာကျပ် (MMK)',
      'currencyUSD': 'အမေရိကန်ဒေါ်လာ (\$)',
      'currencyKRW': 'ကိုရီးယားဝမ် (₩)',

      // Expense Input Modal
      'modalEditExpense': 'ကုန်ကျစရိတ် ပြင်ဆင်ရန်',
      'modalAddExpenseFor': '{date} အတွက် ကုန်ကျစရိတ်ထည့်ရန်',
      'modalExpenseName': 'ကုန်ကျစရိတ်အမည်',
      'modalAmount': 'ပမာဏ ({currency})',
      'modalCategory': 'ကဏ္ဍ',
      'modalTimeOptional': 'အချိန် (ထည့်လိုလျှင်)',
      'modalSaveChanges': 'ပြင်ဆင်မည်',
      'modalSaveExpense': 'သိမ်းဆည်းမည်',
      'modalSave': 'သိမ်းမည်',
      'modalAmountLabel': 'ပမာဏ',
    }
  };

  String t(String key, {Map<String, String> args = const {}}) {
    String value = _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
    
    args.forEach((argKey, argValue) {
      value = value.replaceAll('{$argKey}', argValue);
    });

    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'my'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
