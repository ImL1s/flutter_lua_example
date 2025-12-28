import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_lua_example/main.dart';
import 'package:flutter_lua_example/core/providers/lua_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter Lua Example E2E Tests', () {
    testWidgets('App launches and shows demo page', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Verify app title
      expect(find.text('Flutter Lua Demo'), findsOneWidget);

      // Verify status bar exists
      expect(find.textContaining('Lua 引擎'), findsOneWidget);
    });

    testWidgets('Lua engine initializes successfully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));

      // Wait for engine initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify engine is ready
      expect(find.textContaining('就緒'), findsOneWidget);
      expect(find.text('LuaDardo v0.0.5'), findsOneWidget);
    });

    testWidgets('Example buttons are displayed', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Verify all example buttons exist
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('計數器'), findsOneWidget);
      expect(find.text('Toast'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('循環'), findsOneWidget);
      expect(find.text('函數'), findsOneWidget);
    });

    testWidgets('Execute button exists and is tappable', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and verify execute button
      final executeButton = find.text('執行');
      expect(executeButton, findsOneWidget);

      // Tap the execute button
      await tester.tap(executeButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Hello example executes and shows result', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap Hello button
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check result tab
      expect(find.text('結果'), findsOneWidget);
    });

    testWidgets('Counter example updates state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap counter button
      await tester.tap(find.text('計數器'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to state tab
      await tester.tap(find.text('狀態'));
      await tester.pumpAndSettle();

      // Verify counter state is displayed
      expect(find.text('counter'), findsOneWidget);
    });

    testWidgets('Toast example shows snackbar', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap Toast button
      await tester.tap(find.text('Toast'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify snackbar appears
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Table example creates user state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap Table button
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to state tab
      await tester.tap(find.text('狀態'));
      await tester.pumpAndSettle();

      // Verify user state is displayed
      expect(find.text('user'), findsOneWidget);
    });

    testWidgets('Loop example calculates sum', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap loop button
      await tester.tap(find.text('循環'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to state tab
      await tester.tap(find.text('狀態'));
      await tester.pumpAndSettle();

      // Verify sum state is displayed (1+2+...+10 = 55)
      expect(find.text('sum'), findsOneWidget);
    });

    testWidgets('Function example calculates factorial', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap function button
      await tester.tap(find.text('函數'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check result shows factorial value (5! = 120)
      expect(find.textContaining('120'), findsOneWidget);
    });

    testWidgets('Code editor accepts input', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter custom Lua code
      await tester.enterText(textField, 'return 42');
      await tester.pumpAndSettle();

      // Tap execute
      await tester.tap(find.text('執行'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify result
      expect(find.textContaining('42'), findsWidgets);
    });

    testWidgets('Reset button clears state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // First add some state
      await tester.tap(find.text('計數器'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap reset button
      final resetButton = find.byIcon(Icons.refresh);
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to state tab
      await tester.tap(find.text('狀態'));
      await tester.pumpAndSettle();

      // Verify state is cleared
      expect(find.text('尚無狀態數據'), findsOneWidget);
    });

    testWidgets('Log tab shows execution logs', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Execute Hello example (which uses print)
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to log tab
      await tester.tap(find.text('日誌'));
      await tester.pumpAndSettle();

      // Verify logs are displayed
      expect(find.textContaining('log'), findsWidgets);
    });

    testWidgets('Tab navigation works correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify all tabs exist
      expect(find.text('結果'), findsOneWidget);
      expect(find.text('狀態'), findsOneWidget);
      expect(find.text('日誌'), findsOneWidget);

      // Navigate through tabs
      await tester.tap(find.text('狀態'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('日誌'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('結果'));
      await tester.pumpAndSettle();
    });

    testWidgets('Error handling displays error message', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find text field and enter invalid Lua code
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'invalid lua syntax !!!');
      await tester.pumpAndSettle();

      // Tap execute
      await tester.tap(find.text('執行'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify error is displayed
      expect(find.textContaining('錯誤'), findsWidgets);
    });

    testWidgets('Multiple executions work correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Execute counter multiple times
      await tester.tap(find.text('計數器'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('計數器'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('計數器'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to state tab
      await tester.tap(find.text('狀態'));
      await tester.pumpAndSettle();

      // Verify counter has incremented (should be 3)
      expect(find.textContaining('3'), findsWidgets);
    });
  });
}
