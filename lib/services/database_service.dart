import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/time_record.dart';
import 'work_settings_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final WorkSettingsService _settingsService = WorkSettingsService();

  String _dateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dtr_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE time_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        timeIn TEXT,
        timeOut TEXT,
        totalHours REAL,
        UNIQUE(date)
      )
    ''');
  }

  // Insert or update a time record
  Future<int> saveTimeRecord(TimeRecord record) async {
    final db = await database;
    final recordData = record.toMap();
    final dateKey = _dateKey(record.date).substring(0, 10);
    final lunchStart = await _settingsService.getLunchStart();
    final lunchEnd = await _settingsService.getLunchEnd();
    final shiftStart = await _settingsService.getShiftStart();
    recordData['totalHours'] = _settingsService.calculateWorkedHours(
      record.timeIn,
      record.timeOut,
      lunchStart,
      lunchEnd,
      shiftStart,
    );

    // Check if record for this date already exists
    final existing = await db.query(
      'time_records',
      where: 'substr(date, 1, 10) = ?',
      whereArgs: [dateKey],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      return await db.update(
        'time_records',
        recordData,
        where: 'id = ?',
        whereArgs: [existing[0]['id']],
      );
    } else {
      // Insert new record
      return await db.insert('time_records', recordData);
    }
  }

  // Get all time records
  Future<List<TimeRecord>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_records',
      orderBy: 'date DESC',
    );
    return _applyCalculatedHours(maps);
  }

  // Get record for specific date
  Future<TimeRecord?> getRecordForDate(DateTime date) async {
    final db = await database;
    final dateStr = _dateKey(date).substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'time_records',
      where: 'substr(date, 1, 10) = ?',
      whereArgs: [dateStr],
    );

    if (maps.isNotEmpty) {
      return (await _applyCalculatedHours(maps)).first;
    }
    return null;
  }

  // Get records for date range
  Future<List<TimeRecord>> getRecordsForRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startStr = _dateKey(start).substring(0, 10);
    final endStr = _dateKey(end).substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'time_records',
      where: 'substr(date, 1, 10) BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return _applyCalculatedHours(maps);
  }

  // Get earliest date that has an actual recorded time entry.
  Future<DateTime?> getEarliestRecordedDate() async {
    final db = await database;
    final maps = await db.query(
      'time_records',
      columns: ['date'],
      where: 'timeIn IS NOT NULL OR timeOut IS NOT NULL',
      orderBy: 'date ASC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    final rawDate = maps.first['date'] as String?;
    if (rawDate == null) {
      return null;
    }

    final parsed = DateTime.parse(rawDate);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  // Delete a record
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'time_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total hours for a date range
  Future<double> getTotalHoursForRange(DateTime start, DateTime end) async {
    final records = await getRecordsForRange(start, end);
    double total = 0;
    for (var record in records) {
      if (record.totalHours != null) {
        total += record.totalHours!;
      }
    }
    return total;
  }

  Future<int> clearAllRecords() async {
    final db = await database;
    return db.delete('time_records');
  }

  Future<List<TimeRecord>> _applyCalculatedHours(
    List<Map<String, dynamic>> maps,
  ) async {
    final lunchStart = await _settingsService.getLunchStart();
    final lunchEnd = await _settingsService.getLunchEnd();
    final shiftStart = await _settingsService.getShiftStart();

    return List.generate(maps.length, (index) {
      final record = TimeRecord.fromMap(maps[index]);
      final totalHours = _settingsService.calculateWorkedHours(
        record.timeIn,
        record.timeOut,
        lunchStart,
        lunchEnd,
        shiftStart,
      );
      return record.copyWith(totalHours: totalHours);
    });
  }
}
