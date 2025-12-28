import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_lua_example/main.dart';

void main() {
  testWidgets('App smoke test - launches with demo page', (tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify the app title is displayed
    expect(find.text('Flutter Lua Demo'), findsOneWidget);

    // Verify the Lua code text field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify execute button exists
    expect(find.text('執行'), findsOneWidget);
  });

  testWidgets('Example buttons are visible', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify example buttons
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('計數器'), findsOneWidget);
  });

  testWidgets('Tab bar shows all tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify tabs
    expect(find.text('結果'), findsOneWidget);
    expect(find.text('狀態'), findsOneWidget);
    expect(find.text('日誌'), findsOneWidget);
  });

  testWidgets('Bottom navigation shows both tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify bottom navigation
    expect(find.text('基礎示例'), findsOneWidget);
    expect(find.text('實用場景'), findsOneWidget);
  });

  testWidgets('Can navigate to use cases page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Tap on use cases tab
    await tester.tap(find.text('實用場景'));
    await tester.pumpAndSettle();

    // Verify use cases page is shown
    expect(find.text('實用場景示例'), findsOneWidget);
    expect(find.text('表單驗證'), findsOneWidget);
    expect(find.text('定價引擎'), findsOneWidget);
  });
}
