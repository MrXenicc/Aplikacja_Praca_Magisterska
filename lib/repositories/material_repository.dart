import 'package:sqflite/sqflite.dart';
import '../models/question.dart';
import '../utils/database_helper.dart';

class MaterialRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertQuestion(Question question) async {
    final db = await _dbHelper.database;
    await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestionsByUser(int userId) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps =
    await db.query('questions', where: 'userId = ?', whereArgs: [userId]);

    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getTestQuestionsByUser(int userId) async {
    final db = await _dbHelper.database;
      List<Map<String, dynamic>> maps =
      await db.query('questions', where: 'userId = ?', whereArgs: [userId],limit: 30);

    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<void> deleteQuestion(int questionId) async {
    final db = await _dbHelper.database;
    await db.delete('questions', where: 'id = ?', whereArgs: [questionId]);
  }

  Future<void> updateQuestionWeight(int questionId, int weight) async {
    final db = await _dbHelper.database;
    await db.update('questions', {'weight': weight}, where: 'id = ?', whereArgs: [questionId]);
  }

  Future<void> resetQuestionWeights(int userId) async {
    final db = await _dbHelper.database;
    await db.update('questions', {'weight': 1}, where: 'userId = ?', whereArgs: [userId]);
  }
}
