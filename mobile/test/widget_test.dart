import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whisperback/app.dart';

void main() {
  testWidgets('WhisperBackApp builds', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WhisperBackApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
