import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_example/core/script_manager/script_metadata.dart';
import 'package:flutter_lua_example/core/script_manager/script_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ScriptRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lua_repo_test');

    // Mock path_provider channel
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        });

    repository = ScriptRepository();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ScriptRepository Tests', () {
    test('listScripts returns empty list initially', () async {
      final scripts = await repository.listScripts();
      expect(scripts, isEmpty);
    });

    test('saveScript saves file and updates manifest', () async {
      const metadata = ScriptMetadata(
        id: 'test_script',
        version: '1.0.0',
        checksum: 'abc',
        localPath: 'test_script.lua',
      );

      await repository.saveScript(metadata, 'print("test")');

      final scripts = await repository.listScripts();
      expect(scripts.length, 1);
      expect(scripts.first.id, 'test_script');

      final content = await repository.loadScript(metadata);
      expect(content, 'print("test")');
    });

    test('deleteScript removes file and updates manifest', () async {
      const metadata = ScriptMetadata(
        id: 'test_script',
        version: '1.0.0',
        checksum: 'abc',
        localPath: 'test_script.lua',
      );

      await repository.saveScript(metadata, 'print("test")');
      await repository.deleteScript('test_script');

      final scripts = await repository.listScripts();
      expect(scripts, isEmpty);

      final content = await repository.loadScript(metadata);
      expect(content, isNull);
    });
  });
}
