  import 'package:flutter/material.dart';
  import 'dart:async';
  import 'dart:math';
  import '../models/user.dart';
  import '../repositories/material_repository.dart';
  import '../models/question.dart';
  import '../repositories/test_repository.dart';
  import '../models/test_result.dart';
  import '../repositories/user_repository.dart';

  class TestScreen extends StatefulWidget {
    final User user;
    const TestScreen({Key? key, required this.user}) : super(key: key);

    @override
    TestScreenState createState() => TestScreenState();
  }

  class TestScreenState extends State<TestScreen>
      with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
    final MaterialRepository _materialRepo = MaterialRepository();
    final TestRepository _testRepo = TestRepository();
    List<Question> _questions = [];
    int _currentIndex = 0;
    int _correct = 0;
    int _wrong = 0;
    bool _testFinished = false;
    late int _totalQuestions;
    bool _isPaused = false;
    bool _sessionStarted = false;

    final Stopwatch _stopwatch = Stopwatch();
    Timer? _timer;

    @override
    bool get wantKeepAlive => true;

    Future<void> _loadRandomQuestions() async {
      List<Question> qs =
      await _materialRepo.getTestQuestionsByUser(widget.user.id!);
      qs.shuffle(Random());
      setState(() {
        _questions = qs;
        _totalQuestions = qs.length;
        _currentIndex = 0;
        _correct = 0;
        _wrong = 0;
        _testFinished = false;
        _isPaused = false;
      });
    }

    void _startTest() async {
      await _loadRandomQuestions();
      if (_totalQuestions == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text("Brak pytań. Importuj plik JSON w Materiałach.")),
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
        setState(() {});
      });
    }

    void _answerTest(int selectedIndex) async {
      if (_isPaused) return;
      if (_currentIndex >= _questions.length) return;

      final currentQuestion = _questions[_currentIndex];
      if (selectedIndex == currentQuestion.correctOption) {
        _correct++;
      } else {
        _wrong++;
      }
      if (_currentIndex < _questions.length - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _currentIndex++;
          });
        });
      } else {
        bool passed = _correct / _totalQuestions >= 0.6;
        final result = TestResult(
          userId: widget.user.id!,
          correctAnswers: _correct,
          wrongAnswers: _wrong,
          passed: passed,
          date: DateTime.now().toIso8601String(),
        );
        await _testRepo.insertTestResult(result);
        widget.user.totalTests += 1;
        if (passed) {
          widget.user.passedTests += 1;
        }
        await UserRepository().updateUserStats(widget.user);
        _stopwatch.stop();
        _timer?.cancel();
        setState(() {
          _testFinished = true;
        });
      }
    }

    String _formattedTime() {
      final seconds = _stopwatch.elapsed.inSeconds % 60;
      final minutes = _stopwatch.elapsed.inMinutes;
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    double _calculateMaxWidth(List<String> options, TextStyle style) {
      double maxWidth = 0;
      for (var option in options) {
        final TextPainter tp = TextPainter(
          text: TextSpan(text: option, style: style),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        if (tp.width > maxWidth) {
          maxWidth = tp.width;
        }
      }
      return max(maxWidth + 24, 150);
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
      if (_isPaused && !_testFinished) {
        setState(() {
          _isPaused = false;
        });
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {});
        });
      }
    }

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
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

      if (_currentIndex >= _questions.length && _questions.isNotEmpty) {
        _stopwatch.stop();
        _timer?.cancel();
        _testFinished = true;
      }

      final textTheme = Theme.of(context).textTheme;

      if (!_sessionStarted) {
        return Scaffold(
          appBar: AppBar(title: const Text("Test")),
          body: Center(
            child: ElevatedButton(
              onPressed: _startTest,
              child: const Text("Start"),
            ),
          ),
        );
      }

      if (_questions.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text("Test")),
          body: Center(
            child: Text(
              "Brak pytań. Importuj plik JSON w Materiałach.",
              style: textTheme.titleMedium,
            ),
          ),
        );
      }

      if (_testFinished) {
        bool passed = _correct / _totalQuestions >= 0.6;
        return Scaffold(
          appBar: AppBar(title: const Text("Test")),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Test zakończony!",
                      style:
                      textTheme.titleMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 10),
                  Text("Wynik: $_correct/$_totalQuestions",
                      style: textTheme.bodyLarge),
                  const SizedBox(height: 10),
                  Text(
                    passed ? "Zdany" : "Niezdany",
                    style: textTheme.bodyLarge?.copyWith(
                        color: passed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Czas: ${_formattedTime()}",
                      style: textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startTest,
                    child: const Text("Zacznij ponownie"),
                  )
                ],
              ),
            ),
          ),
        );
      }

      final currentQuestion = _questions[_currentIndex];
      final buttonTextStyle =
          textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
      final maxButtonWidth =
      _calculateMaxWidth(currentQuestion.options, buttonTextStyle);

      return Scaffold(
        appBar: AppBar(title: const Text("Test")),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Pytanie ${_currentIndex + 1}/$_totalQuestions",
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentQuestion.content,
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(currentQuestion.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ConstrainedBox(
                        constraints:
                        BoxConstraints(minWidth: maxButtonWidth, minHeight: 48),
                        child: ElevatedButton(
                          onPressed: _isPaused
                              ? null
                              : () => _answerTest(index),
                          child: Text(
                            currentQuestion.options[index],
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Text("Czas: ${_formattedTime()}",
                      style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
