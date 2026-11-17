import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/detection_event.dart';
import '../models/sound_setting.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  // In-memory fallback storage for Web & Unit Tests where native SQLite is unavailable
  final List<DetectionEvent> _inMemoryEvents = [
    DetectionEvent(
      id: 1,
      soundLabel: 'Doorbell',
      confidence: 0.89,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    DetectionEvent(
      id: 2,
      soundLabel: 'Baby crying',
      confidence: 0.95,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DetectionEvent(
      id: 3,
      soundLabel: 'Smoke / Fire Alarm',
      confidence: 0.99,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
  final Map<String, SoundSetting> _inMemorySettings = {
    for (final entry in kDefaultSounds.entries)
      entry.key: SoundSetting(
        soundLabel: entry.key,
        sensitivity: entry.value,
      )
  };

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null) return _db;
    try {
      _db = await _open();
      return _db;
    } catch (e) {
      debugPrint('AppDatabase: Native database unavailable ($e), using in-memory mode.');
      return null;
    }
  }

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
        for (final entry in kDefaultSounds.entries) {
          await db.insert(
            'SoundSetting',
            SoundSetting(
              soundLabel: entry.key,
              sensitivity: entry.value,
            ).toMap(),
          );
        }
      },
    );
  }

  // ---------- History ----------
  Future<int> insertEvent(DetectionEvent event) async {
    final db = await database;
    if (db != null) {
      return db.insert('DetectionEvent', event.toMap());
    }
    final newId = _inMemoryEvents.length + 1;
    final inMemEvent = DetectionEvent(
      id: newId,
      soundLabel: event.soundLabel,
      confidence: event.confidence,
      timestamp: event.timestamp,
    );
    _inMemoryEvents.insert(0, inMemEvent);
    return newId;
  }

  Future<List<DetectionEvent>> getEvents() async {
    final db = await database;
    if (db != null) {
      final rows = await db.query('DetectionEvent', orderBy: 'timestamp DESC');
      return rows.map(DetectionEvent.fromMap).toList();
    }
    return List.unmodifiable(_inMemoryEvents);
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    if (db != null) {
      await db.delete('DetectionEvent', where: 'id = ?', whereArgs: [id]);
    } else {
      _inMemoryEvents.removeWhere((e) => e.id == id);
    }
  }

  Future<void> clearHistory() async {
    final db = await database;
    if (db != null) {
      await db.delete('DetectionEvent');
    } else {
      _inMemoryEvents.clear();
    }
  }

  // ---------- Settings ----------
  Future<List<SoundSetting>> getSettings() async {
    final db = await database;
    if (db != null) {
      final rows = await db.query('SoundSetting');
      return rows.map(SoundSetting.fromMap).toList();
    }
    return _inMemorySettings.values.toList();
  }

  Future<void> updateSetting(SoundSetting setting) async {
    final db = await database;
    if (db != null) {
      await db.update(
        'SoundSetting',
        setting.toMap(),
        where: 'soundLabel = ?',
        whereArgs: [setting.soundLabel],
      );
    } else {
      _inMemorySettings[setting.soundLabel] = setting;
    }
  }
}
