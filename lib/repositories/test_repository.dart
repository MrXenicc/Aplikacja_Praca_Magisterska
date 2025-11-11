// lib/repositories/test_repository.dart
import 'package:sqflite/sqflite.dart';
import '../models/test_result.dart';
import '../utils/database_helper.dart';

class TestRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertTestResult(TestResult result) async {
    final db = await _dbHelper.database;
    await db.insert('test_results', result.toMap());
  }

  Future<List<TestResult>> getTestResultsByUser(int userId) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query('test_results',
        where: 'userId = ?', whereArgs: [userId]);
    return maps.map((map) => TestResult.fromMap(map)).toList();
  }
}
