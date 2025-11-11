// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'models/user.dart';
import 'repositories/user_repository.dart';
import 'services/notifi_service.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService().initNotification();
    print("NotificationService zainicjalizowany.");
  } catch (e) {
    print("Błąd inicjalizacji NotificationService: $e");
  }

  try {
    tz.initializeTimeZones();
    print("Strefy czasowe zainicjalizowane.");
  } catch (e) {
    print("Błąd inicjalizacji stref czasowych: $e");
  }

  int? userId = await _getSavedUserId();
  User? savedUser;
  if (userId != null) {
    savedUser = await UserRepository().getUserById(userId);
  }

  runApp(QuizApp(savedUser: savedUser));
}

Future<int?> _getSavedUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userId');
}

class QuizApp extends StatefulWidget {
  final User? savedUser;
  const QuizApp({Key? key, this.savedUser}) : super(key: key);

  @override
  _QuizAppState createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  ThemeMode _themeMode = ThemeMode.light;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isDark = prefs.getBool('isDarkMode');
    setState(() {
      _themeMode = (isDark != null && isDark) ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF64B5F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF64B5F6),
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF64B5F6)),
            borderRadius: BorderRadius.circular(12),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64B5F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            elevation: 4,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF64B5F6),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 20, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9575CD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9575CD),
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF9575CD)),
            borderRadius: BorderRadius.circular(12),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9575CD),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            elevation: 4,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF9575CD),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 20, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      home: widget.savedUser != null
          ? MainScreen(
        user: widget.savedUser!,
        onToggleTheme: _toggleTheme,
        isDarkMode: isDarkMode,
      )
          : LoginScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}
