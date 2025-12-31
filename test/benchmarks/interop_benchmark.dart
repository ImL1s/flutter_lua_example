import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/lua_engine/lua_engine.dart';
import '../../lib/core/lua_engine/lua_engine_dart.dart';

void main() {
  late LuaEngine engine;

  setUp(() async {
    engine = LuaEngineDart.create();
    await engine.init();
  });

  group('Interop Benchmarks', () {
    test('Dart -> Lua call overhead (10,000 calls)', () async {
      await engine.eval('''
        function test_func(a, b)
          return a + b
        end
      ''');

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        await engine.call('test_func', [1, 2]);
      }
      stopwatch.stop();

      print('Dart -> Lua (10k calls): ${stopwatch.elapsedMilliseconds} ms');
      print('Average per call: ${stopwatch.elapsedMilliseconds / 10000} ms');
    });

    test('Lua -> Dart call overhead (10,000 calls)', () async {
      engine.registerFunction('dart_func', (args) {
        return (args[0] as num) + (args[1] as num);
      });

      final stopwatch = Stopwatch()..start();
      await engine.eval('''
        for i = 1, 10000 do
          dart_func(1, 2)
        end
      ''');
      stopwatch.stop();

      print('Lua -> Dart (10k calls): ${stopwatch.elapsedMilliseconds} ms');
      print('Average per call: ${stopwatch.elapsedMilliseconds / 10000} ms');
    });
  });
}
