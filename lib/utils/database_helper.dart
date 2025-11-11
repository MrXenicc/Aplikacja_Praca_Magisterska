import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "quiz_app.db");

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        total_tests INTEGER DEFAULT 0,
        passed_tests INTEGER DEFAULT 0,
        total_learning_sessions INTEGER DEFAULT 0,
        total_learning_time INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        content TEXT,
        options TEXT,
        correctOption INTEGER,
        weight INTEGER DEFAULT 1,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        correctAnswers INTEGER,
        wrongAnswers INTEGER,
        passed INTEGER,
        date TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE questions ADD COLUMN weight INTEGER DEFAULT 1");
    }
  }
}
