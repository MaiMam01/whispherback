import 'package:flutter_test/flutter_test.dart';
import 'package:whisperback/services/shuffle/shuffle_engine.dart';

void main() {
  test('shuffle does not repeat until cycle completes', () {
    final engine = ShuffleEngine();
    final ids = ['a', 'b', 'c'];
    final seen = <String>[];

    for (var i = 0; i < 6; i++) {
      seen.add(engine.next(ids)!);
    }

    expect(seen.take(3).toSet().length, 3);
    expect(seen.skip(3).take(3).toSet().length, 3);
  });
}
