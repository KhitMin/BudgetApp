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
      'others': 'Others',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'action': 'Action',
      'confirmDelete': 'Confirm Delete',
      'confirmDeletePrompt': 'Are you sure you want to delete this item?',
      'fillAllFields': 'Please fill all fields!',

      // Bottom Navigation
      'navHome': 'Home',
      'navBudget': 'Expenses',
      'navPlanning': 'Planning',
      'navReporting': 'Reporting',
      'navSetting': 'Setting',

      // Home Page
      'homeSummaryTitle': 'Summary for {month}',
      'homeIncome': 'Income',
      'homeSpent': 'Spent',
      'homeRemaining': 'Remaining',
      'homeAddExpense': 'Add Expense',
      'homeViewReports': 'View Reports',
      'homeRecentTransactions': 'Recent Transactions',
      'homeNoTransactions': 'No transactions yet.',
      'homeTopCategories': 'Top Spending Categories',
      'homeFinancialTip': 'Tip: Review your monthly subscriptions to find potential savings!',

      // Budget Page
      'budgetTotalFor': 'Total for {month}',
      'budgetSelectDayPrompt': 'Select a day to view or add expenses',
      'budgetNoExpenseForToday': 'No expense records for today.',
      'budgetAddExpenseTooltip': 'Add Expense',
      'budgetCategoryLabel': 'Category: {category}',

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

      // Expense Input Modal
      'modalEditExpense': 'Edit Expense',
      'modalAddExpenseFor': 'Add Expense for {date}',
      'modalExpenseName': 'Expense Name',
      'modalAmount': 'Amount ({currency})',
      'modalCategory': 'Category',
      'modalSaveChanges': 'Save Changes',
      'modalSaveExpense': 'Save Expense',
    },
    'my': {
      // General
      'appName': 'ငွေကြေးစီမံသူ',
      'others': 'အခြား',
      'save': 'သိမ်းမည်',
      'edit': 'ပြင်မည်',
      'delete': 'ဖျက်မည်',
      'cancel': 'မလုပ်တော့ပါ',
      'action': 'လုပ်ဆောင်ချက်',
      'confirmDelete': 'ဖျက်ရန် အတည်ပြုပါ',
      'confirmDeletePrompt': 'ဤအချက်အလက်ကို ဖျက်မှာသေချာပါသလား?',
      'fillAllFields': 'အကွက်အားလုံးကို ဖြည့်စွက်ပါ!',

      // Bottom Navigation
      'navHome': 'ပင်မ',
      'navBudget': 'ထွက်ငွေ',
      'navPlanning': 'အစီအစဉ်',
      'navReporting': 'မှတ်တမ်း',
      'navSetting': 'ဆက်တင်',

      // Home Page
      'homeSummaryTitle': '{month} အတွက် အကျဉ်းချုပ်',
      'homeIncome': 'ဝင်ငွေ',
      'homeSpent': 'သုံးငွေ',
      'homeRemaining': 'လက်ကျန်',
      'homeAddExpense': 'ကုန်ကျစရိတ်ထည့်မည်',
      'homeViewReports': 'မှတ်တမ်းကြည့်မည်',
      'homeRecentTransactions': 'မကြာမီက သုံးစွဲမှုများ',
      'homeNoTransactions': 'သုံးစွဲမှု မှတ်တမ်းမရှိသေးပါ',
      'homeTopCategories': 'အသုံးအများဆုံး ကဏ္ဍများ',
      'homeFinancialTip': 'အကြံပြုချက်: လစဉ်ကြေးပေးသွင်းထားသည်များကို ပြန်လည်စစ်ဆေးပြီး ငွေစုနိုင်သည်!',

      // Budget Page
      'budgetTotalFor': '{month} စုစုပေါင်း',
      'budgetSelectDayPrompt': 'ကုန်ကျစရိတ်ကြည့်ရန် (သို့) ထည့်ရန် နေ့ရက်ရွေးပါ',
      'budgetNoExpenseForToday': 'ယနေ့အတွက် ကုန်ကျစရိတ် မှတ်တမ်းမရှိပါ',
      'budgetAddExpenseTooltip': 'ကုန်ကျစရိတ်ထည့်မည်',
      'budgetCategoryLabel': 'ကဏ္ဍ: {category}',

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

      // Expense Input Modal
      'modalEditExpense': 'ကုန်ကျစရိတ် ပြင်ဆင်ရန်',
      'modalAddExpenseFor': '{date} အတွက် ကုန်ကျစရိတ်ထည့်ရန်',
      'modalExpenseName': 'ကုန်ကျစရိတ်အမည်',
      'modalAmount': 'ပမာဏ ({currency})',
      'modalCategory': 'ကဏ္ဍ',
      'modalSaveChanges': 'အပြောင်းအလဲကို သိမ်းဆည်းမည်',
      'modalSaveExpense': 'ကုန်ကျစရိတ် သိမ်းဆည်းမည်',
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
