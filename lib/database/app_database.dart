import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/detection_event.dart';
import '../models/sound_setting.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'echoalert.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE DetectionEvent(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            soundLabel TEXT NOT NULL,
            confidence REAL NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE SoundSetting(
            soundLabel TEXT PRIMARY KEY,
            isEnabled INTEGER NOT NULL,
            sensitivity REAL NOT NULL
          )
        ''');
        // මුලින්ම database එක හැදෙද්දී sound 5ම default settings එක්ක දානවා
        for (final entry in kDefaultSounds.entries) {
          await db.insert(
            'SoundSetting',
            SoundSetting(soundLabel: entry.key, sensitivity: entry.value)
                .toMap(),
          );
        }
      },
    );
  }

  // ---------- History ----------
  Future<int> insertEvent(DetectionEvent event) async {
    final db = await database;
    return db.insert('DetectionEvent', event.toMap());
  }

  Future<List<DetectionEvent>> getEvents() async {
    final db = await database;
    final rows = await db.query('DetectionEvent', orderBy: 'timestamp DESC');
    return rows.map(DetectionEvent.fromMap).toList();
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('DetectionEvent', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('DetectionEvent');
  }

  // ---------- Settings ----------
  Future<List<SoundSetting>> getSettings() async {
    final db = await database;
    final rows = await db.query('SoundSetting');
    return rows.map(SoundSetting.fromMap).toList();
  }

  Future<void> updateSetting(SoundSetting setting) async {
    final db = await database;
    await db.update(
      'SoundSetting',
      setting.toMap(),
      where: 'soundLabel = ?',
      whereArgs: [setting.soundLabel],
    );
  }
}