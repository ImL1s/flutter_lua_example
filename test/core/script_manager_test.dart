import 'package:flutter_lua_example/core/providers/script_provider.dart';
import 'package:flutter_lua_example/core/script_manager/script_manager.dart';
import 'package:flutter_lua_example/core/script_manager/script_metadata.dart';
import 'package:flutter_lua_example/core/script_manager/script_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'script_manager_test.mocks.dart';

@GenerateMocks([ScriptRepository])
void main() {
  late MockScriptRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockScriptRepository();
    when(mockRepository.listScripts()).thenAnswer((_) async => []);
    when(mockRepository.saveScript(any, any)).thenAnswer((_) async => {});
  });

  ScriptManager getManager() {
    container = ProviderContainer(
      overrides: [scriptRepositoryProvider.overrideWithValue(mockRepository)],
    );
    return container.read(scriptManagerProvider.notifier);
  }

  tearDown(() {
    container.dispose();
  });

  group('ScriptManager Tests', () {
    test('Mock download success (calc_script)', () async {
      final manager = getManager();

      final result = await manager.downloadAndVerifyScript(
        id: 'test_calc',
        url: 'mock://calc_script',
        version: '1.0.0',
        expectedChecksum: 'MOCK_SKIP',
      );

      expect(result.id, 'test_calc');
      verify(mockRepository.saveScript(any, any)).called(1);
    });

    test('Mock malicious script fails checksum implicitly', () async {
      // Note: malicious script in mock protocol sends specific content
      // If we provide a REAL checksum that doesn't match 'print("This is a malicious script")', it should fail.
      // But if we pass 'MOCK_SKIP', it passes.
      // To test failure, we must NOT pass 'MOCK_SKIP' and pass a mismatching checksum.

      final manager = getManager();

      expect(
        () => manager.downloadAndVerifyScript(
          id: 'test_malicious',
          url: 'mock://malicious', // Returns known content
          version: '1.0.0',
          expectedChecksum: 'MISMATCH_CHECKSUM', // Should fail
        ),
        throwsException,
      );
    });

    test('Concurrent downloads logic', () async {
      final manager = getManager();

      final future1 = manager.downloadAndVerifyScript(
        id: 'script1',
        url: 'mock://calc_script',
        version: '1.0',
        expectedChecksum: 'MOCK_SKIP',
      );

      final future2 = manager.downloadAndVerifyScript(
        id: 'script2',
        url: 'mock://interop_script',
        version: '1.0',
        expectedChecksum: 'MOCK_SKIP',
      );

      await Future.wait([future1, future2]);

      verify(mockRepository.saveScript(any, any)).called(2);
    });
  });
}
