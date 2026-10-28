import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'problem_list_screen.dart';
import 'submission_screen.dart';
import 'end_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _refreshCounter = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _refreshCounter++;
    });
  }

  void _toTop() {
    setState(() {
      _currentIndex = 0;
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProblemListScreen(key: ValueKey('prob_$_refreshCounter')),
      const SubmissionScreen(),
      EndScreen(
        key: ValueKey('end_$_refreshCounter'),
        onBackToProblems: () => _onTabTapped(0),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline VPLAS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.topButtonColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _toTop,
              child: const Text(
                'TOP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.darkBg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Offline VPLAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Verilog CH1: Verilog Introduction',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppTheme.primary),
              title: const Text('Problems'),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.of(context).pop();
                _onTabTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded, color: AppTheme.primary),
              title: const Text('Submission'),
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.of(context).pop();
                _onTabTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppTheme.primary),
              title: const Text('End'),
              selected: _currentIndex == 2,
              onTap: () {
                Navigator.of(context).pop();
                _onTabTapped(2);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: AppTheme.primary),
            label: 'Problems',
          ),
          NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send_rounded, color: AppTheme.primary),
            label: 'Submission',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: AppTheme.primary),
            label: 'End',
          ),
        ],
      ),
    );
  }
}
