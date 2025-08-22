import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // AppBar ကို MainScreen မှာ ထားပြီးဖြစ်လို့ ဒီမှာထပ်မထည့်တော့ပါ
    return const Center(
      child: Text(
        'Home Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}