// lib/screens/profile_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/material_repository.dart';
import '../widgets/animated_theme_switch.dart';
import 'login_screen.dart';
import '../services/availability_service.dart';
import '../services/flashcard_service.dart';
import '../services/notifi_service.dart';

class Achievement {
  final String title;
  final bool unlocked;

  Achievement({required this.title, required this.unlocked});
}

class ProfileScreen extends StatefulWidget {
  final User user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  ProfileScreen({
    Key? key,
    required this.user,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _currentUser;

  int _availableStartHour = 9;
  int _availableStartMinute = 0;
  int _availableEndHour = 20;
  int _availableEndMinute = 0;
  bool _cyclicStudyRemindersEnabled = true;
  final AvailabilityService _availabilityService = AvailabilityService();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadAvailableHours();
    _loadCyclicReminderState();
  }

  Future<void> _loadAvailableHours() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _availableStartHour = prefs.getInt('availableStartHour') ?? 9;
      _availableStartMinute = prefs.getInt('availableStartMinute') ?? 0;
      _availableEndHour = prefs.getInt('availableEndHour') ?? 20;
      _availableEndMinute = prefs.getInt('availableEndMinute') ?? 0;
    });
  }

  Future<void> _saveAvailableHours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('availableStartHour', _availableStartHour);
    await prefs.setInt('availableStartMinute', _availableStartMinute);
    await prefs.setInt('availableEndHour', _availableEndHour);
    await prefs.setInt('availableEndMinute', _availableEndMinute);
  }

  Future<void> _loadCyclicReminderState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cyclicStudyRemindersEnabled = prefs.getBool('cyclicStudyRemindersEnabled') ?? false;
    });
  }

  Future<void> _saveCyclicReminderState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cyclicStudyRemindersEnabled', value);
  }

  Future<void> _setAvailableStartTime() async {
    DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      currentTime: DateTime(0, 0, 0, _availableStartHour, _availableStartMinute),
      onConfirm: (time) async {
        setState(() {
          _availableStartHour = time.hour;
          _availableStartMinute = time.minute;
        });
        await _saveAvailableHours();
      },
    );
  }

  Future<void> _setAvailableEndTime() async {
    DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      currentTime: DateTime(0, 0, 0, _availableEndHour, _availableEndMinute),
      onConfirm: (time) async {
        setState(() {
          _availableEndHour = time.hour;
          _availableEndMinute = time.minute;
        });
        await _saveAvailableHours();
      },
    );
  }

  List<Achievement> _calculateAchievements() {
    return [
      Achievement(
        title: "Pierwszy test ukończony",
        unlocked: _currentUser.totalTests >= 1,
      ),
      Achievement(
        title: "Test zaliczony",
        unlocked: _currentUser.passedTests >= 1,
      ),
      Achievement(
        title: "5 testów zaliczonych",
        unlocked: _currentUser.passedTests >= 5,
      ),
      Achievement(
        title: "10 testów zaliczonych",
        unlocked: _currentUser.passedTests >= 10,
      ),
      Achievement(
        title: "100 testów wykonanych",
        unlocked: _currentUser.totalTests >= 100,
      ),
      Achievement(
        title: "Pierwsza sesja nauki",
        unlocked: _currentUser.totalLearningSessions >= 1,
      ),
      Achievement(
        title: "50 sesji nauki",
        unlocked: _currentUser.totalLearningSessions >= 50,
      ),
      Achievement(
        title: "1 godzina nauki",
        unlocked: _currentUser.totalLearningTime >= 3600,
      ),
      Achievement(
        title: "5 godzin nauki",
        unlocked: _currentUser.totalLearningTime >= 18000,
      ),
    ];
  }

  void _changeUsername() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _nameController =
        TextEditingController(text: _currentUser.username);
        return AlertDialog(
          title: const Text("Zmień nazwę użytkownika"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nowa nazwa"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _currentUser.username = _nameController.text;
                });
                final userRepo = UserRepository();
                await userRepo.updateUserStats(_currentUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Nazwa użytkownika zmieniona")),
                );
              },
              child: const Text("Zmień"),
            ),
          ],
        );
      },
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _passwordController = TextEditingController();
        return AlertDialog(
          title: const Text("Zmień hasło"),
          content: TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Nowe hasło"),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _currentUser.password = _passwordController.text;
                });
                final userRepo = UserRepository();
                await userRepo.updateUserStats(_currentUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hasło zmienione")),
                );
              },
              child: const Text("Zmień"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshUserData() async {
    final userRepo = UserRepository();
    final updatedUser = await userRepo.getUserById(_currentUser.id!);
    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  void _showAchievementsDialog() {
    final achievements = _calculateAchievements();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Osiągnięcia"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final ach = achievements[index];
                return ListTile(
                  leading: Icon(
                    ach.unlocked ? Icons.star : Icons.star_border,
                    color: ach.unlocked ? Colors.amber : Colors.grey,
                  ),
                  title: Text(
                    ach.title,
                    style: TextStyle(
                      color: ach.unlocked
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Zamknij",
                style: TextStyle(
                  color: widget.isDarkMode ? const Color(0xFF9575CD) : const Color(0xFF64B5F6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSection() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Statystyki",
              style: textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Odśwież statystyki",
              onPressed: () async {
                await _refreshUserData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Statystyki odświeżone")),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text("Testy"),
            subtitle: Text("Wykonanych: ${_currentUser.totalTests}\nZaliczonych: ${_currentUser.passedTests}"),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.school),
            title: const Text("Nauka"),
            subtitle: Text("Sesji: ${_currentUser.totalLearningSessions}\nŁączny czas nauki: ${_currentUser.totalLearningTime} sek"),
          ),
        ),
      ],
    );
  }


  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Osiągnięcia", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _showAchievementsDialog,
          icon: const Icon(Icons.emoji_events),
          label: const Text("Pokaż osiągnięcia"),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Powiadomienia", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: _setAvailableStartTime,
              child: Text("Od: ${_availableStartHour.toString().padLeft(2, '0')}:${_availableStartMinute.toString().padLeft(2, '0')}"),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _setAvailableEndTime,
              child: Text("Do: ${_availableEndHour.toString().padLeft(2, '0')}:${_availableEndMinute.toString().padLeft(2, '0')}"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Powiadomienia cykliczne o nauce", style: Theme.of(context).textTheme.bodyLarge),
            Switch(
              value: _cyclicStudyRemindersEnabled,
              onChanged: (bool value) async {
                await Future.wait(List.generate(100, (index) =>
                    NotificationService().cancelNotification(300 + index)
                ));
                await _saveCyclicReminderState(value);
                setState(() {
                  _cyclicStudyRemindersEnabled = value;
                });
                if (value) {
                  await FlashcardService().scheduleCyclicStudyReminders(
                    _currentUser.id!,
                    _availableStartHour,
                    _availableStartMinute,
                    _availableEndHour,
                    _availableEndMinute,
                    intervalMinutes: 120,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cykliczne powiadomienia o nauce włączone")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cykliczne powiadomienia o nauce wyłączone")),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            DateTime? selectedDate = await DatePicker.showDateTimePicker(
              context,
              showTitleActions: true,
              currentTime: DateTime.now(),
              onConfirm: (date) => date,
              onCancel: () => null,
            );
            if (selectedDate != null) {
              await NotificationService().scheduleNotification(
                id: 0,
                title: "Przypomnienie o nauce",
                body: "Czas na nowy test! Sprawdź swoje postępy.",
                scheduledNotificationDateTime: selectedDate,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Powiadomienie ustawione na ${selectedDate.toLocal()}")),
              );
            }
          },
          child: const Text("Ustaw pojedyncze powiadomienie"),
        ),
      ],
    );
  }

  Widget _buildOtherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Inne", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            await MaterialRepository().resetQuestionWeights(_currentUser.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Wagi pytań zostały zresetowane")),
            );
          },
          child: const Text("Resetuj wagi pytań"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _changeUsername,
          child: const Text("Zmień nazwę użytkownika"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _changePassword,
          child: const Text("Zmień hasło"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(
                  onToggleTheme: widget.onToggleTheme,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            );
          },
          child: const Text("Wyloguj się"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Witaj, ${_currentUser.username}!", style: textTheme.titleMedium?.copyWith(fontSize: 22)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Zmiana motywu", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  AnimatedThemeSwitch(
                    isDark: widget.isDarkMode,
                    onToggle: (newValue) {
                      widget.onToggleTheme();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Statystyki
              _buildStatsSection(),
              const SizedBox(height: 20),
              // Osiągnięcia
              _buildAchievementsSection(),
              const SizedBox(height: 20),
              // Powiadomienia
              _buildNotificationsSection(),
              const SizedBox(height: 20),
              // Inne ustawienia
              _buildOtherSection(),
            ],
          ),
        ),
      ),
    );
  }
}
