import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'summary_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainScreen({super.key, required this.onToggleTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onToggleTheme: widget.onToggleTheme),
      const SummaryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return Scaffold(
            appBar: AppBar(title: const Text('MoneyMind')),
            body: Row(
              children: [
                Expanded(child: _pages[0]),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[1]),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: _pages[_currentIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.list), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Summary'),
              ],
            ),
          );
        }
      },
    );
  }
}
