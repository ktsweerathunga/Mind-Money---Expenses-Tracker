import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screens/home_screen.dart';
import 'Screens/main_screen.dart';
import 'Screens/welcome_screen.dart';
import 'Models/transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  final seen = prefs.getBool('seenOnboarding') ?? true; // onboarding assumed done
  final name = prefs.getString('username');

  Widget startScreen;
  if (!seen) {
    // If you have onboarding
    // startScreen = const OnboardingScreen();
    startScreen = const WelcomeScreen();
  } else if (name == null || name.isEmpty) {
    startScreen = const WelcomeScreen();
  } else {
    startScreen = MoneyMindApp(isDarkMode: isDark);
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: startScreen,
  ));
}

class MoneyMindApp extends StatefulWidget {
  final bool isDarkMode;
  const MoneyMindApp({super.key, required this.isDarkMode});

  @override
  State<MoneyMindApp> createState() => _MoneyMindAppState();
}

class _MoneyMindAppState extends State<MoneyMindApp> {
  late bool _isDark = widget.isDarkMode;

  void _toggleTheme() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _isDark = !_isDark;
    prefs.setBool('darkMode', _isDark);
  });
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: _isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: MainScreen(onToggleTheme: _toggleTheme),
    );
  }
}
