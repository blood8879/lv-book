import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await databaseFactory.openDatabase(
      path,
      options: openDatabaseOptions(),
    );
  }

  /// Options shared by the app database and tests (in-memory ffi DBs).
  @visibleForTesting
  OpenDatabaseOptions openDatabaseOptions() {
    return OpenDatabaseOptions(
      version: AppConstants.dbVersion,
      onConfigure: _configureDB,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Replaces the shared database instance (tests only).
  @visibleForTesting
  void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  /// SQLite leaves foreign keys off per connection by default, which would
  /// silently disable ON DELETE CASCADE / SET NULL.
  Future<void> _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE benchmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        elevation REAL NOT NULL,
        description TEXT,
        location_hint TEXT,
        protection_note TEXT,
        last_verified_at TEXT,
        status TEXT NOT NULL DEFAULT 'available',
        kind TEXT NOT NULL DEFAULT 'bm',
        photo_path TEXT,
        latitude REAL,
        longitude REAL,
        coordinate_accuracy_m REAL,
        coordinate_captured_at TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE field_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        start_bm_id INTEGER,
        start_elevation REAL,
        closing_mode TEXT NOT NULL DEFAULT 'none',
        closing_bm_id INTEGER,
        closing_elevation REAL,
        reduction_method TEXT NOT NULL DEFAULT 'heightOfInstrument',
        memo TEXT,
        surveyor TEXT,
        checker TEXT,
        instrument TEXT,
        weather TEXT,
        work_section TEXT,
        job_number TEXT,
        review_status TEXT NOT NULL DEFAULT 'draft',
        review_memo TEXT,
        reviewed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (start_bm_id) REFERENCES benchmarks (id) ON DELETE SET NULL,
        FOREIGN KEY (closing_bm_id) REFERENCES benchmarks (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        field_book_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        station_name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'normal',
        bs REAL,
        fs REAL,
        ih REAL,
        gh REAL,
        manual_tp INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (field_book_id) REFERENCES field_books (id) ON DELETE CASCADE
      )
    ''');

    await _createSettingsTable(db);
    await _createQuickMemosTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE field_books ADD COLUMN start_elevation REAL',
      );
    }
    if (oldVersion < 3) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE field_books ADD COLUMN surveyor TEXT');
      await db.execute('ALTER TABLE field_books ADD COLUMN checker TEXT');
      await db.execute('ALTER TABLE field_books ADD COLUMN instrument TEXT');
      await db.execute('ALTER TABLE field_books ADD COLUMN weather TEXT');
      await db.execute('ALTER TABLE field_books ADD COLUMN work_section TEXT');
      await db.execute('ALTER TABLE field_books ADD COLUMN job_number TEXT');
      await db.execute('ALTER TABLE benchmarks ADD COLUMN location_hint TEXT');
      await db.execute(
        'ALTER TABLE benchmarks ADD COLUMN protection_note TEXT',
      );
      await db.execute(
        'ALTER TABLE benchmarks ADD COLUMN last_verified_at TEXT',
      );
      await db.execute(
        "ALTER TABLE benchmarks ADD COLUMN status TEXT NOT NULL DEFAULT 'available'",
      );
      await db.execute(
        'ALTER TABLE measurements ADD COLUMN manual_tp INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE field_books ADD COLUMN review_status TEXT NOT NULL DEFAULT 'draft'",
      );
      await db.execute('ALTER TABLE field_books ADD COLUMN review_memo TEXT');
      await db.execute('ALTER TABLE field_books ADD COLUMN reviewed_at TEXT');
    }
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE benchmarks ADD COLUMN kind TEXT NOT NULL DEFAULT 'bm'",
      );
      await db.execute('ALTER TABLE benchmarks ADD COLUMN photo_path TEXT');
      await db.execute('ALTER TABLE benchmarks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE benchmarks ADD COLUMN longitude REAL');
      await db.execute(
        'ALTER TABLE benchmarks ADD COLUMN coordinate_accuracy_m REAL',
      );
      await db.execute(
        'ALTER TABLE benchmarks ADD COLUMN coordinate_captured_at TEXT',
      );
    }
    if (oldVersion < 7) {
      await _createQuickMemosTable(db);
    }
    if (oldVersion < 8) {
      await _deleteOrphanRows(db);
    }
    if (oldVersion < 9) {
      await _addClosingReference(db);
    }
    if (oldVersion < 10) {
      await _addReductionMethod(db);
    }
  }

  /// v10: per field book reduction method (HI / rise and fall). Existing
  /// books keep the HI presentation. Idempotent like [_addClosingReference].
  Future<void> _addReductionMethod(Database db) async {
    final columns = {
      for (final row in await db.rawQuery('PRAGMA table_info(field_books)'))
        row['name'] as String,
    };
    if (!columns.contains('reduction_method')) {
      await db.execute(
        "ALTER TABLE field_books ADD COLUMN reduction_method TEXT NOT NULL "
        "DEFAULT 'heightOfInstrument'",
      );
    }
  }

  /// v9: closing reference (closing BM / known closing RL) per field book.
  /// Existing books get 'none', i.e. only the arithmetic check as before.
  /// Skips columns that already exist so a partially upgraded file reopens.
  Future<void> _addClosingReference(Database db) async {
    final columns = {
      for (final row in await db.rawQuery('PRAGMA table_info(field_books)'))
        row['name'] as String,
    };
    if (!columns.contains('closing_mode')) {
      await db.execute(
        "ALTER TABLE field_books ADD COLUMN closing_mode TEXT NOT NULL DEFAULT 'none'",
      );
    }
    // A column added with REFERENCES must default to NULL (it does).
    if (!columns.contains('closing_bm_id')) {
      await db.execute(
        'ALTER TABLE field_books ADD COLUMN closing_bm_id INTEGER '
        'REFERENCES benchmarks (id) ON DELETE SET NULL',
      );
    }
    if (!columns.contains('closing_elevation')) {
      await db.execute(
        'ALTER TABLE field_books ADD COLUMN closing_elevation REAL',
      );
    }
  }

  /// Before v8 foreign keys were never enabled, so deleting a project / field
  /// book / BM left dangling children behind. Remove them once.
  Future<void> _deleteOrphanRows(Database db) async {
    await db.execute(
      'DELETE FROM field_books WHERE project_id NOT IN (SELECT id FROM projects)',
    );
    await db.execute(
      'DELETE FROM benchmarks WHERE project_id NOT IN (SELECT id FROM projects)',
    );
    await db.execute(
      'DELETE FROM measurements '
      'WHERE field_book_id NOT IN (SELECT id FROM field_books)',
    );
    await db.execute(
      'UPDATE field_books SET start_bm_id = NULL '
      'WHERE start_bm_id IS NOT NULL '
      'AND start_bm_id NOT IN (SELECT id FROM benchmarks)',
    );
  }

  Future<void> _createQuickMemosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quick_memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT,
        audio_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
