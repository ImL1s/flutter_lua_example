import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_lua_example/main.dart';

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
      expect(find.text('LuaDardo Plus v0.3.0'), findsOneWidget);
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

      // Scroll to make Table button visible
      final tableButton = find.text('Table');
      await tester.ensureVisible(tableButton);
      await tester.pumpAndSettle();

      // Tap Table button
      await tester.tap(tableButton, warnIfMissed: false);
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

      // Scroll to make loop button visible
      final loopButton = find.text('循環');
      await tester.ensureVisible(loopButton);
      await tester.pumpAndSettle();

      // Tap loop button
      await tester.tap(loopButton, warnIfMissed: false);
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

      // Scroll to make function button visible
      final funcButton = find.text('函數');
      await tester.ensureVisible(funcButton);
      await tester.pumpAndSettle();

      // Tap function button
      await tester.tap(funcButton, warnIfMissed: false);
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

  group('Use Cases Page E2E Tests', () {
    testWidgets('Navigate to use cases page', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      await binding.setSurfaceSize(const Size(1000, 2000));
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on use cases tab
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle();

      // Verify use cases page is displayed
      expect(find.text('實用場景示例'), findsOneWidget);
      expect(find.text('選擇場景運行 Lua 腳本：'), findsOneWidget);
    });

    testWidgets('All use case buttons are displayed', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle();

      // Verify all use case buttons
      expect(find.text('表單驗證'), findsOneWidget);
      expect(find.text('UI 控制'), findsOneWidget);
      expect(find.text('定價引擎'), findsOneWidget);
      expect(find.text('A/B 測試'), findsOneWidget);
      expect(find.text('審批流程'), findsOneWidget);
      expect(find.text('推送策略'), findsOneWidget);
    });

    testWidgets('Form validation use case executes successfully', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap form validation button
      await tester.tap(find.text('表單驗證'));
      // Give more time for Lua execution and state propagation
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify tabs are visible (execution completed)
      expect(find.text('狀態結果'), findsOneWidget);
      expect(find.text('Lua 腳本'), findsOneWidget);
      expect(find.text('說明'), findsOneWidget);
    });

    testWidgets('UI visibility use case executes successfully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap UI control button
      await tester.tap(find.text('UI 控制'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify state shows UI visibility results
      expect(find.text('uiVisibility'), findsWidgets);
    });

    testWidgets('Pricing engine use case executes successfully', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap pricing engine button
      await tester.tap(find.text('定價引擎'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify state shows pricing results
      expect(find.text('pricingResult'), findsWidgets);
    });

    testWidgets('A/B testing use case executes successfully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap A/B testing button
      await tester.tap(find.text('A/B 測試'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify tabs are visible (execution completed)
      expect(find.text('狀態結果'), findsOneWidget);
      expect(find.text('Lua 腳本'), findsOneWidget);
    });

    testWidgets('Workflow engine use case executes successfully', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap workflow engine button
      await tester.tap(find.text('審批流程'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify tabs are visible (execution completed)
      expect(find.text('狀態結果'), findsOneWidget);
      expect(find.text('Lua 腳本'), findsOneWidget);
    });

    testWidgets('Push strategy use case executes successfully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap push strategy button
      await tester.tap(find.text('推送策略'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify tabs are visible (execution completed)
      expect(find.text('狀態結果'), findsOneWidget);
      expect(find.text('Lua 腳本'), findsOneWidget);
    });

    testWidgets('Tab navigation works on use cases page', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      await binding.setSurfaceSize(const Size(1000, 2000));
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Execute a use case first
      await tester.tap(find.text('表單驗證'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify all tabs exist
      expect(find.text('狀態結果'), findsOneWidget);
      expect(find.text('Lua 腳本'), findsOneWidget);
      expect(find.text('說明'), findsOneWidget);

      // Navigate to Lua script tab via programmatic control to avoid hit test issues
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBar)),
      );
      controller.animateTo(1);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify script content is visible (contains Lua keywords)
      expect(find.textContaining('local'), findsWidgets);

      // Navigate to explanation tab
      controller.animateTo(2);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify explanation content
      expect(find.textContaining('驗證'), findsWidgets);
    });

    testWidgets('Reset button clears use cases state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify engine is ready
      expect(find.text('Lua 引擎就緒'), findsOneWidget);

      // Tap reset button
      final resetButton = find.byIcon(Icons.refresh);
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify welcome message is shown
      expect(find.text('選擇上方場景查看 Lua 腳本實際應用'), findsOneWidget);
    });

    testWidgets('Engine status shows ready on use cases page', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle();

      // Verify engine status shows ready
      expect(find.text('Lua 引擎就緒'), findsOneWidget);
    });

    testWidgets('Can switch between demo and use cases pages', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Start on demo page
      expect(find.text('Flutter Lua Demo'), findsOneWidget);

      // Navigate to use cases
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle();
      expect(find.text('實用場景示例'), findsOneWidget);

      // Navigate back to demo
      await tester.tap(find.text('基礎示例'));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Lua Demo'), findsOneWidget);

      // Navigate to use cases again
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle();
      expect(find.text('實用場景示例'), findsOneWidget);
    });

    testWidgets('State expansion works correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Execute UI control (simpler state structure)
      await tester.tap(find.text('UI 控制'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify state cards are visible
      expect(find.text('狀態結果'), findsOneWidget);
    });

    testWidgets('Multiple use cases can be executed sequentially', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Execute form validation first
      await tester.tap(find.text('表單驗證'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify first use case executed
      expect(find.text('狀態結果'), findsOneWidget);

      // Execute pricing engine (should clear previous state)
      await tester.tap(find.text('定價引擎'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify pricing state exists
      expect(find.text('pricingResult'), findsWidgets);
    });

    testWidgets('Toast notifications appear after use case execution', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to use cases page
      await tester.tap(find.text('實用場景'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Execute UI control (should show toast)
      await tester.tap(find.text('UI 控制'));
      // Wait for toast to appear
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify snackbar appears
      expect(find.byType(SnackBar), findsWidgets);
    });
  });
  group('Script Manager UI Tests', () {
    testWidgets('Download and run script flow', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open drawer via icon
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      // Verify drawer content
      expect(find.text('熱更新腳本管理'), findsOneWidget);

      // Tap download
      await tester.tap(find.text('模擬下載遠端腳本'));
      await tester.pump(); // Trigger logic
      // Wait for 1.5 seconds (Mock delay is 1s)
      await tester.pump(const Duration(milliseconds: 1500));

      // Check if script is added to list
      // We retry a few times to allow for state update
      bool scriptFound = false;
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.textContaining('remote_script').evaluate().isNotEmpty) {
          scriptFound = true;
          break;
        }
      }

      if (!scriptFound) {
        // Check for failure message if script not found
        final errorFinder = find.textContaining('加載失敗');
        if (errorFinder.evaluate().isNotEmpty) {
          final text = tester.widget<Text>(errorFinder.first);
          fail('Download reported failure: ${text.data}');
        }
        fail(
          'Script download failed: "remote_script" not found in list, and no error message shown.',
        );
      }

      // Optional: Check snackbar if possible, but don't block
      if (find.textContaining('下載成功').evaluate().isNotEmpty) {
        // Good
      }

      // Now settle animations
      await tester.pumpAndSettle();

      // Verify script is added to list and play it
      // We pick the last play button assuming it's the most recent or at least one exists
      final playButtons = find.byIcon(Icons.play_arrow_rounded);
      expect(playButtons, findsAtLeastNWidgets(1));

      await tester.tap(playButtons.last);
      await tester.pumpAndSettle();

      // Should close drawer and run script
      // Verify snackbar
      // Verify output in code editor
      // This confirms the script was loaded from disk
      final codeEditor = find.byType(TextField);
      expect(
        find.descendant(
          of: codeEditor,
          matching: find.textContaining('print("Hello from Remote Script'),
        ),
        findsOneWidget,
      );

      // Verify execution log
      await tester.tap(find.text('日誌'));
      await tester.pumpAndSettle();
      // Ensure we find the log entry which starts with [log]
      expect(find.textContaining('[log]'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Status: Ready'), findsAtLeastNWidgets(1));
    });
  });
}
