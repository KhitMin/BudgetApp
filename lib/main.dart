import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// pages
import 'pages/home_page.dart';
import 'pages/budget_page.dart';
import 'pages/planning_page.dart';
import 'pages/reporting_page.dart';
import 'pages/setting_page.dart';

// providers
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

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
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        // add default material localizations so widgets like date pickers work
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

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    BudgetPage(),
    PlanningPage(),
    ReportingPage(),  // Index 3
    SettingPage(),    // Index 4
  ];

  // tab ကိုနှိပ်လိုက်ရင် page ပြောင်းပေးမယ့် function
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar ကို page တစ်ခုချင်းစီမှာ သီးသန့်ထားလိုပါက ဒီ AppBar ကို ဖယ်ရှားနိုင်ပါသည်
      appBar: AppBar(
        title: const Text('My Budget Planner'),
        elevation: 1,
      ),
      // ရွေးထားတဲ့ index အလိုက် သက်ဆိုင်ရာ page ကို ပြသပါမယ်
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Footer Navbar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Reporting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Setting',
          ),
        ],
        currentIndex: _selectedIndex,
        // ရွေးထားတဲ့ tab ကို အရောင်ပေါ်လွင်အောင်လုပ်ရန်
        selectedItemColor: Colors.blue[800], 
        // မရွေးထားတဲ့ tab တွေကို အရောင်မှိန်ရန်
        unselectedItemColor: Colors.grey, 
        // label တွေကို အမြဲပြသရန်
        showUnselectedLabels: true, 
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // tab 5 ခုအတွက် fixed type သုံးပါ
      ),
    );
  }
}