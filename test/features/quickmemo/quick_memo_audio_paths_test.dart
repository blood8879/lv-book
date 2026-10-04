import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/quickmemo/data/quick_memo_audio_paths.dart';

void main() {
  const docs = '/var/mobile/Containers/Data/Application/NEW/Documents';
  const oldDocs = '/var/mobile/Containers/Data/Application/OLD/Documents';

  group('toStored', () {
    test('stores paths inside documents relative to it', () {
      expect(
        QuickMemoAudioPaths.toStored('$docs/quick_memos/memo_1.m4a', docs),
        'quick_memos/memo_1.m4a',
      );
    });

    test('keeps paths outside documents and relative paths unchanged', () {
      expect(
        QuickMemoAudioPaths.toStored('/tmp/memo_1.m4a', docs),
        '/tmp/memo_1.m4a',
      );
      expect(
        QuickMemoAudioPaths.toStored('quick_memos/memo_1.m4a', docs),
        'quick_memos/memo_1.m4a',
      );
    });
  });

  group('resolve', () {
    test('joins relative paths onto the current documents dir', () {
      expect(
        QuickMemoAudioPaths.resolve(
          'quick_memos/memo_1.m4a',
          docs,
          exists: (_) => false,
        ),
        '$docs/quick_memos/memo_1.m4a',
      );
    });

    test('keeps a legacy absolute path that still exists', () {
      const legacy = '$oldDocs/quick_memos/memo_1.m4a';
      expect(
        QuickMemoAudioPaths.resolve(
          legacy,
          docs,
          exists: (path) => path == legacy,
        ),
        legacy,
      );
    });

    test('re-anchors a stale legacy absolute path under current docs', () {
      const legacy = '$oldDocs/quick_memos/memo_1.m4a';
      const expected = '$docs/quick_memos/memo_1.m4a';
      expect(
        QuickMemoAudioPaths.resolve(
          legacy,
          docs,
          exists: (path) => path == expected,
        ),
        expected,
      );
    });

    test('falls back to basename under quick_memos dir', () {
      const legacy = '$oldDocs/other/memo_2.m4a';
      const expected = '$docs/quick_memos/memo_2.m4a';
      expect(
        QuickMemoAudioPaths.resolve(
          legacy,
          docs,
          exists: (path) => path == expected,
        ),
        expected,
      );
    });

    test('returns best candidate when nothing exists', () {
      expect(
        QuickMemoAudioPaths.resolve(
          '$oldDocs/quick_memos/memo_3.m4a',
          docs,
          exists: (_) => false,
        ),
        '$docs/quick_memos/memo_3.m4a',
      );
    });
  });
}
