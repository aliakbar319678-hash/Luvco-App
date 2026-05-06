import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luvco_logo/main.dart';

void main() {
  testWidgets('LuvcoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuvcoApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
