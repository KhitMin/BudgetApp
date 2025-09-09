import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// pages
import 'pages/home_page.dart';
import 'pages/budget_page.dart';
import 'pages/planning_page.dart';
import 'pages/reporting_page.dart';
import 'pages/records_page.dart';

// providers
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/currency_provider.dart';

// l10n
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CurrencyProvider(prefs)),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'My Budget App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('my')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

// BottomNavigationBar ကို ထိန်းချုပ်မယ့် Screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Tab ကို ပြောင်းလဲပေးမယ့် function
  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // late final အဖြစ်ကြေညာထားသော variable
  late final List<Widget> _widgetOptions;

  // initState() function က build() မတိုင်ခင်မှာ အရင် အလုပ်လုပ်ပါတယ်
  // ဒီနေရာမှာ _widgetOptions ကို တန်ဖိုးထည့်သွင်းပေးရပါမယ်
  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomePage(onNavigateToTab: _changeTab),
      const BudgetPage(),
      const PlanningPage(),
      const ReportingPage(),
      const RecordsPage(),
    ];
  }

  // tab ကိုနှိပ်လိုက်ရင် page ပြောင်းပေးမယ့် function
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('appTitle')),
        elevation: 1,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: loc.t('navHome'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: loc.t('navBudget'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            label: loc.t('navPlanning'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: loc.t('navReporting'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: loc.t('navRecords'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),

    );
  }
}
