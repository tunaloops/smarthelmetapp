import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/crash_log.dart';
import '../models/emergency_contact.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'contacts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE crash_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            location TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertContact(EmergencyContact contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<EmergencyContact>> getContacts() async {
    final db = await database;
    final result = await db.query('contacts');
    return result.map((map) => EmergencyContact.fromMap(map)).toList();
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCrashLog(CrashLog log) async {
    final db = await database;
    return await db.insert('crash_logs', log.toMap());
  }

  Future<List<CrashLog>> getCrashLogs() async {
    final db = await database;
    final result = await db.query('crash_logs', orderBy: "id DESC");
    return result.map((map) => CrashLog.fromMap(map)).toList();
  }
}