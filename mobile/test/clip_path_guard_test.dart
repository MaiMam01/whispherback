import 'package:flutter_test/flutter_test.dart';
import 'package:whisperback/services/audio/clip_path_guard.dart';

void main() {
  setUp(() {
    ClipPathGuard.bindClipsRootForTests('/app/documents/clips');
  });

  test('rejects asset and demo paths', () {
    expect(ClipPathGuard.isAllowed('asset://foo'), isFalse);
    expect(ClipPathGuard.isAllowed('demo://clip'), isFalse);
  });

  test('rejects paths outside clips directory', () {
    expect(ClipPathGuard.isAllowed('/system/evil.mp3'), isFalse);
  });

  test('allows files inside clips directory', () {
    expect(
      ClipPathGuard.isAllowed('/app/documents/clips/abc.m4a'),
      isTrue,
    );
  });

  test('allows only mp3 and m4a imports', () {
    expect(ClipPathGuard.isAllowedImportExtension('/a/song.mp3'), isTrue);
    expect(ClipPathGuard.isAllowedImportExtension('/a/song.M4A'), isTrue);
    expect(ClipPathGuard.isAllowedImportExtension('/a/song.wav'), isFalse);
  });
}
