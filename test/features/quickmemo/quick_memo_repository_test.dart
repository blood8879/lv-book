import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/quickmemo/data/quick_memo_repository.dart';
import 'package:lv_book/features/quickmemo/domain/quick_memo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late QuickMemoRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE quick_memos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              text TEXT,
              audio_path TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    repository = QuickMemoRepository(databaseProvider: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create then list returns saved memo', () async {
    await repository.create(
      QuickMemo(text: '현장 노트', createdAt: DateTime(2026, 1, 1, 9)),
    );

    final memos = await repository.list();
    expect(memos, hasLength(1));
    expect(memos.first.text, '현장 노트');
    expect(memos.first.id, isNotNull);
  });

  test('list is ordered newest first', () async {
    await repository.create(
      QuickMemo(text: '오래된 메모', createdAt: DateTime(2026, 1, 1, 9)),
    );
    await repository.create(
      QuickMemo(text: '최신 메모', createdAt: DateTime(2026, 1, 2, 9)),
    );

    final memos = await repository.list();
    expect(memos.map((m) => m.text).toList(), ['최신 메모', '오래된 메모']);
  });

  test('delete removes the memo', () async {
    final id = await repository.create(
      QuickMemo(text: '삭제 대상', createdAt: DateTime(2026, 1, 1)),
    );

    await repository.delete(id);

    expect(await repository.list(), isEmpty);
  });
}
