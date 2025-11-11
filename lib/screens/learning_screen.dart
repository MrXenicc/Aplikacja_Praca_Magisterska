// lib/screens/learning_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user.dart';
import '../models/question.dart';
import '../repositories/material_repository.dart';
import '../repositories/user_repository.dart';
import '../services/notifi_service.dart';
import '../services/flashcard_service.dart';

class LearningScreen extends StatefulWidget {
  final User user;
  const LearningScreen({Key? key, required this.user}) : super(key: key);

  @override
  LearningScreenState createState() => LearningScreenState();
}

class LearningScreenState extends State<LearningScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final MaterialRepository _materialRepo = MaterialRepository();

  List<Question> _questions = [];
  Map<int, int> _weights = {};
  Question? _currentQuestion;
  Question? _lastQuestion;
  String _feedback = "";
  Color _feedbackColor = Colors.black;
  bool _learningFinished = false;
  bool _isLoading = true;
  bool _isPaused = false;
  bool _sessionStarted = false;
  bool _isProcessingAnswer = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _breakNotificationSent = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _learningFinished = false;
      _feedback = "";
      _isPaused = false;
      _sessionStarted = false;
      _breakNotificationSent = false;
    });
    List<Question> qs =
    await _materialRepo.getQuestionsByUser(widget.user.id!);
    setState(() {
      _questions = qs;
      _weights.clear();
      for (var q in qs) {
        int id = q.id ?? q.content.hashCode;
        _weights[id] = q.weight;
      }
      _isLoading = false;
    });
  }

  void _selectNextQuestion() {
    if (_questions.isEmpty) return;
    int totalWeight = 0;
    for (var q in _questions) {
      int id = q.id ?? q.content.hashCode;
      totalWeight += _weights[id] ?? 1;
    }
    if (totalWeight <= 0) {
      _currentQuestion = _questions[Random().nextInt(_questions.length)];
      return;
    }
    Question? selected;
    do {
      int rnd = Random().nextInt(totalWeight);
      for (var q in _questions) {
        int id = q.id ?? q.content.hashCode;
        int weight = _weights[id] ?? 1;
        if (rnd < weight) {
          selected = q;
          break;
        }
        rnd -= weight;
      }
    } while (_questions.length > 1 &&
        _lastQuestion != null &&
        selected != null &&
        selected.id == _lastQuestion!.id &&
        selected.content == _lastQuestion!.content);
    _currentQuestion = selected ?? _questions.last;
    _lastQuestion = _currentQuestion;
  }

  void _checkForBreakNotification() {
    if (!_breakNotificationSent && _stopwatch.elapsed.inSeconds >= 1800) {
      NotificationService().showNotification(
        id: 1,
        title: "Przerwa",
        body: "Uczysz się już dłużej niż 30 minut. Zrób sobie może krótką przerwę!",
      );
      _breakNotificationSent = true;
    }
  }


  void _finishSession() async {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _learningFinished = true;
    });

    int sessionTime = _stopwatch.elapsed.inSeconds;
    widget.user.totalLearningSessions += 1;
    widget.user.totalLearningTime += sessionTime;
    await UserRepository().updateUserStats(widget.user);

    String flashcardMessage =
    await FlashcardService().getFlashcardsMessage(widget.user.id!);
    if (flashcardMessage.isNotEmpty) {
      await NotificationService().showFlashcardNotificationImmediate(
        id: 100,
        title: "Przypomnij sobie jeszcze raz!",
        body: flashcardMessage,
      );
    }
  }

  void _startSession() async {
    await _loadQuestions();
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Brak pytań. Importuj plik JSON w Materiałach.")),
      );
      return;
    }
    setState(() {
      _sessionStarted = true;
    });
    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkForBreakNotification();
      setState(() {});
    });
    _selectNextQuestion();
  }

  void _answerQuestion(int selectedIndex) {
    if (_currentQuestion == null || _isPaused || _isProcessingAnswer) return;
    setState(() {
      _isProcessingAnswer = true;
    });
    int id = _currentQuestion!.id ?? _currentQuestion!.content.hashCode;
    if (selectedIndex == _currentQuestion!.correctOption) {
      setState(() {
        _feedback = "Dobrze!";
        _feedbackColor = Colors.green;
      });
      _weights[id] = (_weights[id] ?? 1) > 1 ? (_weights[id]! - 1) : 1;
    } else {
      setState(() {
        _feedback = "Źle, spróbuj ponownie.";
        _feedbackColor = Colors.red;
      });
      _weights[id] = (_weights[id] ?? 1) + 1;
    }
    if (_currentQuestion!.id != null) {
      _materialRepo.updateQuestionWeight(_currentQuestion!.id!, _weights[id]!);
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _feedback = "";
        _isProcessingAnswer = false;
      });
      _selectNextQuestion();
      setState(() {});
    });
  }

  void pauseSession() {
    if (!_isPaused && _sessionStarted) {
      setState(() {
        _isPaused = true;
      });
      _stopwatch.stop();
      _timer?.cancel();
    }
  }

  void resumeSession() {
    if (_isPaused && !_learningFinished) {
      setState(() {
        _isPaused = false;
      });
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _checkForBreakNotification();
        setState(() {});
      });
    }
  }


  String _formattedTime() {
    final seconds = _stopwatch.elapsed.inSeconds % 60;
    final minutes = _stopwatch.elapsed.inMinutes;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadQuestions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseSession();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;

    if (!_sessionStarted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Nauka")),
        body: Center(
          child: ElevatedButton(
            onPressed: _startSession,
            child: const Text("Start"),
          ),
        ),
      );
    }

    if (_learningFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Nauka")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Sesja nauki zakończona!",
                    style: textTheme.titleMedium?.copyWith(fontSize: 20)),
                const SizedBox(height: 10),
                Text("Czas sesji: ${_formattedTime()}",
                    style: textTheme.bodyLarge),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _sessionStarted = false;
                      _learningFinished = false;
                    });
                    _loadQuestions();
                  },
                  child: const Text("Zacznij ponownie"),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (_currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Nauka")),
        body: Center(
          child: Text("Brak pytań", style: textTheme.titleMedium),
        ),
      );
    }

    double maxButtonWidth = 150;
    for (var option in _currentQuestion!.options) {
      final tp = TextPainter(
        text: TextSpan(text: option, style: textTheme.bodyLarge),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      if (tp.width > maxButtonWidth) {
        maxButtonWidth = tp.width + 24;
      }
    }
    int currentWeight =
        _weights[_currentQuestion!.id ?? _currentQuestion!.content.hashCode] ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text("Nauka")),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Czas: ${_formattedTime()}", style: textTheme.bodyLarge),
                const SizedBox(height: 10),
                Text(
                  _currentQuestion!.content,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...List.generate(_currentQuestion!.options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: maxButtonWidth,
                        minHeight: 48,
                      ),
                      child: ElevatedButton(
                        onPressed: _isPaused ? null : () => _answerQuestion(index),
                        child: Text(
                          _currentQuestion!.options[index],
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  _feedback,
                  style: textTheme.bodyLarge?.copyWith(color: _feedbackColor),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_isPaused) {
                        resumeSession();
                      } else {
                        pauseSession();
                      }
                    });
                  },
                  child: Text(_isPaused ? "Wznów" : "Pauza"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _finishSession,
                  child: const Text("Zakończ sesję nauki"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
