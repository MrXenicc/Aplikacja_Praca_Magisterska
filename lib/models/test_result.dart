// lib/models/test_result.dart
class TestResult {
  int? id;
  int userId;
  int correctAnswers;
  int wrongAnswers;
  bool passed;
  String date;

  TestResult({
    this.id,
    required this.userId,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.passed,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'passed': passed ? 1 : 0,
      'date': date,
    };
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'],
      userId: map['userId'],
      correctAnswers: map['correctAnswers'],
      wrongAnswers: map['wrongAnswers'],
      passed: map['passed'] == 1,
      date: map['date'],
    );
  }
}
