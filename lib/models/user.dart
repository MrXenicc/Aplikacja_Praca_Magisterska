// lib/models/user.dart
class User {
  int? id;
  String username;
  String password;
  int totalTests;
  int passedTests;
  int totalLearningSessions;
  int totalLearningTime;

  User({
    this.id,
    required this.username,
    required this.password,
    this.totalTests = 0,
    this.passedTests = 0,
    this.totalLearningSessions = 0,
    this.totalLearningTime = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'total_tests': totalTests,
      'passed_tests': passedTests,
      'total_learning_sessions': totalLearningSessions,
      'total_learning_time': totalLearningTime,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      totalTests: map['total_tests'],
      passedTests: map['passed_tests'],
      totalLearningSessions: map['total_learning_sessions'],
      totalLearningTime: map['total_learning_time'],
    );
  }
}
