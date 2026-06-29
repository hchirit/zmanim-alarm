import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/alarm.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _db;

  DatabaseService._internal();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = p.join(await getDatabasesPath(), 'zmanim_alarm.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE alarms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            zman_type TEXT NOT NULL,
            offset_minutes INTEGER NOT NULL DEFAULT 0,
            days_of_week TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
            is_enabled INTEGER NOT NULL DEFAULT 1,
            snooze_duration INTEGER NOT NULL DEFAULT 5,
            vibrate INTEGER NOT NULL DEFAULT 1,
            sound_key TEXT NOT NULL DEFAULT 'system',
            ring_duration_seconds INTEGER NOT NULL DEFAULT 0,
            custom_sound_path TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE alarms ADD COLUMN sound_key TEXT NOT NULL DEFAULT 'system'");
          await db.execute(
              'ALTER TABLE alarms ADD COLUMN ring_duration_seconds INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE alarms ADD COLUMN custom_sound_path TEXT');
        }
      },
    );
  }

  Future<int> insertAlarm(Alarm alarm) async {
    final db = await database;
    return db.insert('alarms', alarm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateAlarm(Alarm alarm) async {
    final db = await database;
    return db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    final db = await database;
    return db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Alarm>> getAllAlarms() async {
    final db = await database;
    final maps = await db.query('alarms', orderBy: 'created_at ASC');
    return maps.map(Alarm.fromMap).toList();
  }

  Future<Alarm?> getAlarm(int id) async {
    final db = await database;
    final maps =
        await db.query('alarms', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Alarm.fromMap(maps.first);
  }

  Future<int> setAlarmEnabled(int id, bool enabled) async {
    final db = await database;
    return db.update(
      'alarms',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
