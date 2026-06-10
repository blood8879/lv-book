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

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
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
        FOREIGN KEY (start_bm_id) REFERENCES benchmarks (id) ON DELETE SET NULL
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
