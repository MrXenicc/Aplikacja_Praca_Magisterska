// lib/services/flashcard_service.dart
import 'package:aplikacja_jan_sobczak/models/question.dart';
import 'package:aplikacja_jan_sobczak/repositories/material_repository.dart';
import 'package:aplikacja_jan_sobczak/services/notifi_service.dart';

class FlashcardService {
  final MaterialRepository _materialRepo = MaterialRepository();

  Future<String> getFlashcardsMessage(int userId) async {
    List<Question> questions = await _materialRepo.getQuestionsByUser(userId);
    if (questions.isEmpty) return "";
    questions.sort((a, b) => b.weight.compareTo(a.weight));
    List<Question> topQuestions = questions.take(5).toList();
    String message = topQuestions
        .map((q) => "${q.content}\nOdpowiedź: ${q.options[q.correctOption]}")
        .join("\n\n");
    if (message.length > 400) {
      topQuestions = questions.take(3).toList();
      message = topQuestions
          .map((q) => "${q.content}\nOdpowiedź: ${q.options[q.correctOption]}")
          .join("\n\n");
    }
    return message;
  }

  Future<void> scheduleCyclicStudyReminders(
      int userId, int startHour, int startMinute, int endHour, int endMinute,
      {int intervalMinutes = 120}) async {
    List<DateTime> scheduledTimes = [];
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day, startHour, startMinute);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, endHour, endMinute);
    if (now.isBefore(todayStart)) {
      DateTime candidate = todayStart;
      while (candidate.isBefore(todayEnd) || candidate.isAtSameMomentAs(todayEnd)) {
        scheduledTimes.add(candidate);
        candidate = candidate.add(Duration(minutes: intervalMinutes));
      }
    } else if (now.isBefore(todayEnd)) {
      DateTime candidate = todayStart;
      while (candidate.isBefore(now)) {
        candidate = candidate.add(Duration(minutes: intervalMinutes));
      }
      if (candidate.isBefore(todayEnd) || candidate.isAtSameMomentAs(todayEnd)) {
        scheduledTimes.add(candidate);
        candidate = candidate.add(Duration(minutes: intervalMinutes));
        while (candidate.isBefore(todayEnd) || candidate.isAtSameMomentAs(todayEnd)) {
          scheduledTimes.add(candidate);
          candidate = candidate.add(Duration(minutes: intervalMinutes));
        }
      }
    } else {
      DateTime tomorrowStart = DateTime(now.year, now.month, now.day, startHour, startMinute).add(Duration(days: 1));
      DateTime tomorrowEnd = DateTime(now.year, now.month, now.day, endHour, endMinute).add(Duration(days: 1));
      DateTime candidate = tomorrowStart;
      while (candidate.isBefore(tomorrowEnd) || candidate.isAtSameMomentAs(tomorrowEnd)) {
        scheduledTimes.add(candidate);
        candidate = candidate.add(Duration(minutes: intervalMinutes));
      }
    }
    int notifId = 300;
    for (DateTime scheduledTime in scheduledTimes) {
      await NotificationService().scheduleCyclicNotification(
        id: notifId,
        title: "Przypomnienie o nauce",
        body: "Czas na naukę! Sprawdź swoje materiały i postępy.",
        scheduledNotificationDateTime: scheduledTime,
      );
      notifId++;
    }
  }
}
