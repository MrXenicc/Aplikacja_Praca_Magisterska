// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'materials_screen.dart';
import 'learning_screen.dart';
import 'test_screen.dart';
import 'profile_screen.dart';
import '../models/user.dart';

class MainScreen extends StatefulWidget {
  final User user;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  const MainScreen({
    Key? key,
    required this.user,
    required this.onToggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<LearningScreenState> learningScreenKey = GlobalKey<LearningScreenState>();
  final GlobalKey<TestScreenState> testScreenKey = GlobalKey<TestScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MaterialsScreen(user: widget.user),
      LearningScreen(key: learningScreenKey, user: widget.user),
      TestScreen(key: testScreenKey, user: widget.user),
      ProfileScreen(user: widget.user, onToggleTheme: widget.onToggleTheme, isDarkMode: widget.isDarkMode),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == 1 && index != 1) {
      learningScreenKey.currentState?.pauseSession();
    }
    if (_selectedIndex == 2 && index != 2) {
      testScreenKey.currentState?.pauseSession();
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      testScreenKey.currentState?.resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Materiały'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Nauka'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
