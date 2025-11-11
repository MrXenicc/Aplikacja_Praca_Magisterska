// lib/services/json_parser_service.dart
import 'dart:convert';
import '../models/question.dart';

class JsonParserService {
  List<Question> parseQuestions(String jsonString, int userId) {
    final List<dynamic> data = json.decode(jsonString);
    return data.map((item) {
      return Question(
        userId: userId,
        content: item['content'],
        options: List<String>.from(item['options']),
        correctOption: item['correctOption'],
      );
    }).toList();
  }
}
