import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_example/core/lua_engine/lua_engine_dart.dart';

void main() {
  group('Infinite Loop Safety Test', () {
    late LuaEngineDart engine;

    setUp(() {
      engine = LuaEngineDart.create();
    });

    test('Should throw exception when instruction limit is exceeded', () async {
      // Initialize with a low instruction count limit (e.g., 1000)
      await engine.init(instructionLimit: 1000);

      // A simple infinite loop script
      const script = '''
        local i = 0
        while true do
          i = i + 1
        end
      ''';

      // Verify that execution throws an exception instead of hanging
      // We expect a generic Exception with our message
      expect(
        () async => await engine.eval(script),
        throwsA(
          predicate((e) => e.toString().contains('Instruction limit exceeded')),
        ),
      );
    });

    test('Should run normally within instruction limit', () async {
      // Limit to 1000 instructions
      await engine.init(instructionLimit: 1000);

      // A script that runs few instructions
      const script = '''
        local a = 10
        local b = 20
        return a + b
      ''';

      final result = await engine.eval(script);
      expect(result, 30.0); // Lua numbers are doubles by default
    });
  });
}
