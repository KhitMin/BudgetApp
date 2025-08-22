import 'package:flutter/material.dart';

// သင်สร้างထားတဲ့ page တွေကို import လုပ်ပါ
// မှတ်ချက်: သင့် project ရဲ့ file structure အတိုင်း path ကို ပြင်ဆင်ရန်လို सकताသည်
import 'pages/home_page.dart';
import 'pages/budget_page.dart';
import 'pages/planning_page.dart';
import 'pages/reporting_page.dart';
import 'pages/setting_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Budget App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // App တစ်ခုလုံးအတွက် font ကို Zawgyi သို့မဟုတ် Unicode သတ်မှတ်နိုင်သည်
        // fontFamily: 'Pyidaungsu', 
      ),
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
  // လက်ရှိရွေးထားတဲ့ tab index ကို သိမ်းရန်
  int _selectedIndex = 0; 

  // tab တစ်ခုချင်းစီအတွက် ပြသမယ့် page တွေ
  // ဒီနေရာမှာ သင်สร้างထားတဲ့ page widget တွေကို ထည့်ပေးရပါမယ်
  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),       // Index 0
    BudgetPage(),     // Index 1
    PlanningPage(),   // Index 2
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