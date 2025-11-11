import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> createUser(String username, String password) async {
    final db = await _dbHelper.database;
    try {
      await db.insert('users', {
        'username': username,
        'password': password,
        'total_tests': 0,
        'passed_tests': 0,
        'total_learning_sessions': 0,
        'total_learning_time': 0,
      });
      return true;
    } catch (e) {
      print("Error creating user: $e");
      return false;
    }
  }

  Future<User?> authenticate(String username, String password) async {
    final db = await _dbHelper.database;
    List<Map> maps = await db.query('users',
        where: 'username = ? and password = ?', whereArgs: [username, password]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUserStats(User user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

}


