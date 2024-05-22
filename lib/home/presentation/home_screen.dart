import 'package:flutter/material.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/home/presentation/calendar_page.dart';
import 'package:wallet/home/presentation/charts_page.dart';
import 'package:wallet/home/presentation/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (value) {
          setState(() {
            _index = value;
          });
        },
        children: const [
          CounterPage(),
          CalendarPage(),
          Center(
            child: CandleChartPage(),
          ),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          _controller.animateToPage(
            value,
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Counter',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
