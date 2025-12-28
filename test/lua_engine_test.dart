import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_example/core/lua_engine/lua_engine.dart';
import 'package:flutter_lua_example/core/lua_engine/lua_engine_dart.dart';

void main() {
  group('LuaEngineDart', () {
    late LuaEngineDart engine;

    setUp(() async {
      engine = LuaEngineDart.create();
      await engine.init();
    });

    tearDown(() async {
      await engine.dispose();
    });

    group('Initialization', () {
      test('engine initializes with ready state', () {
        expect(engine.state, equals(LuaEngineState.ready));
        expect(engine.isReady, isTrue);
      });

      test('engine info contains correct metadata', () {
        final info = engine.engineInfo;
        expect(info['name'], equals('LuaDardo'));
        expect(info['version'], equals('0.0.5'));
        expect(info['luaVersion'], equals('5.3'));
        expect(info['platform'], equals('Dart'));
        expect(info['sandboxed'], isTrue);
      });

      test('double initialization throws error', () async {
        expect(
          () async => await engine.init(),
          throwsA(isA<LuaInitException>()),
        );
      });
    });

    group('Basic Evaluation', () {
      test('evaluates simple arithmetic', () async {
        final result = await engine.eval('return 1 + 2');
        expect(result, equals(3));
      });

      test('evaluates string concatenation', () async {
        final result = await engine.eval('return "Hello" .. " " .. "World"');
        expect(result, equals('Hello World'));
      });

      test('evaluates boolean expressions', () async {
        final result = await engine.eval('return true and false');
        expect(result, equals(false));
      });

      test('evaluates nil', () async {
        final result = await engine.eval('return nil');
        expect(result, isNull);
      });

      test('evaluates table as map', () async {
        final result = await engine.eval('return {a = 1, b = 2}');
        expect(result, isA<Map>());
        expect(result['a'], equals(1));
        expect(result['b'], equals(2));
      });

      test('evaluates array table as list-like map', () async {
        final result = await engine.eval('return {10, 20, 30}');
        expect(result, isA<Map>());
      });

      test('handles syntax errors gracefully', () async {
        expect(
          () async => await engine.eval('invalid lua !!!'),
          throwsA(isA<LuaExecutionException>()),
        );
      });

      test('handles runtime errors gracefully', () async {
        expect(
          () async => await engine.eval('error("test error")'),
          throwsA(isA<LuaExecutionException>()),
        );
      });
    });

    group('Global Variables', () {
      test('sets and gets string global', () {
        engine.setGlobal('testStr', 'hello');
        expect(engine.getGlobal('testStr'), equals('hello'));
      });

      test('sets and gets number global', () {
        engine.setGlobal('testNum', 42);
        expect(engine.getGlobal('testNum'), equals(42));
      });

      test('sets and gets boolean global', () {
        engine.setGlobal('testBool', true);
        expect(engine.getGlobal('testBool'), equals(true));
      });

      test('sets and gets null global', () {
        engine.setGlobal('testNil', null);
        expect(engine.getGlobal('testNil'), isNull);
      });

      test('sets and gets map global', () {
        engine.setGlobal('testMap', {'key': 'value'});
        final result = engine.getGlobal('testMap');
        expect(result, isA<Map>());
        expect(result['key'], equals('value'));
      });

      test('sets and gets list global', () {
        engine.setGlobal('testList', [1, 2, 3]);
        final result = engine.getGlobal('testList');
        expect(result, isA<Map>());
      });

      test('hasGlobal returns true for existing global', () {
        engine.setGlobal('exists', 123);
        expect(engine.hasGlobal('exists'), isTrue);
      });

      test('hasGlobal returns false for non-existing global', () {
        expect(engine.hasGlobal('notExists'), isFalse);
      });
    });

    group('Function Calls', () {
      test('calls simple function', () async {
        await engine.eval('''
          function add(a, b)
            return a + b
          end
        ''');

        final result = await engine.call('add', [10, 20]);
        expect(result, equals(30));
      });

      test('calls function with no arguments', () async {
        await engine.eval('''
          function getAnswer()
            return 42
          end
        ''');

        final result = await engine.call('getAnswer');
        expect(result, equals(42));
      });

      test('calls function with string arguments', () async {
        await engine.eval('''
          function greet(name)
            return "Hello, " .. name
          end
        ''');

        final result = await engine.call('greet', ['World']);
        expect(result, equals('Hello, World'));
      });

      test('throws error for non-existent function', () async {
        expect(
          () async => await engine.call('nonExistent'),
          throwsA(isA<LuaCallException>()),
        );
      });

      test('calls recursive function', () async {
        await engine.eval('''
          function factorial(n)
            if n <= 1 then
              return 1
            end
            return n * factorial(n - 1)
          end
        ''');

        final result = await engine.call('factorial', [5]);
        expect(result, equals(120));
      });
    });

    group('Dart Function Registration', () {
      test('registers and calls Dart function', () async {
        engine.registerFunction('multiply', (args) {
          return (args[0] as num) * (args[1] as num);
        });

        final result = await engine.eval('''
          return callNative('multiply', 6, 7)
        ''');

        expect(result, equals(42));
      });

      test('registers function that returns string', () async {
        engine.registerFunction('getGreeting', (args) {
          return 'Hello, ${args[0]}!';
        });

        final result = await engine.eval('''
          return callNative('getGreeting', 'Lua')
        ''');

        expect(result, equals('Hello, Lua!'));
      });

      test('registers function that returns null', () async {
        engine.registerFunction('doNothing', (args) => null);

        final result = await engine.eval('''
          return callNative('doNothing')
        ''');

        expect(result, isNull);
      });

      test('unregisters function', () async {
        engine.registerFunction('temp', (args) => 'temp');
        engine.unregisterFunction('temp');

        final result = await engine.eval('''
          local success, err = callNative('temp')
          return err
        ''');

        expect(result, contains('not found'));
      });

      test('registers multiple functions', () async {
        engine.registerFunctions({
          'funcA': (args) => 'A',
          'funcB': (args) => 'B',
        });

        final resultA = await engine.eval("return callNative('funcA')");
        final resultB = await engine.eval("return callNative('funcB')");

        expect(resultA, equals('A'));
        expect(resultB, equals('B'));
      });
    });

    group('Table Fields', () {
      test('sets and gets table field', () async {
        await engine.eval('myTable = {}');
        engine.setTableField('myTable', 'name', 'test');

        final result = engine.getTableField('myTable', 'name');
        expect(result, equals('test'));
      });

      test('creates table if not exists', () {
        engine.setTableField('newTable', 'key', 'value');
        final result = engine.getTableField('newTable', 'key');
        expect(result, equals('value'));
      });

      test('returns null for non-existent table field', () async {
        await engine.eval('emptyTable = {}');
        final result = engine.getTableField('emptyTable', 'missing');
        expect(result, isNull);
      });
    });

    group('Events', () {
      test('emits events through stream', () async {
        final events = <LuaEvent>[];
        final subscription = engine.events.listen(events.add);

        engine.emitEvent(LuaEvent.log('info', 'test message'));

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.length, equals(1));
        expect(events[0].type, equals(LuaEventType.log));
        expect(events[0].data['message'], equals('test message'));
      });

      test('print function emits log event', () async {
        final events = <LuaEvent>[];
        final subscription = engine.events.listen(events.add);

        await engine.eval('print("Hello from Lua")');

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.any((e) => e.type == LuaEventType.log), isTrue);
      });

      test('emit function sends custom event', () async {
        final events = <LuaEvent>[];
        final subscription = engine.events.listen(events.add);

        await engine.eval('''
          emit('toast', {message = 'Test toast', type = 'success'})
        ''');

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.any((e) => e.type == LuaEventType.toast), isTrue);
      });
    });

    group('Sandbox Mode', () {
      test('os library is removed in sandbox mode', () async {
        final result = await engine.eval('return os');
        expect(result, isNull);
      });

      test('io library is removed in sandbox mode', () async {
        final result = await engine.eval('return io');
        expect(result, isNull);
      });

      test('debug library is removed in sandbox mode', () async {
        final result = await engine.eval('return debug');
        expect(result, isNull);
      });

      test('dofile is removed in sandbox mode', () async {
        final result = await engine.eval('return dofile');
        expect(result, isNull);
      });

      test('loadfile is removed in sandbox mode', () async {
        final result = await engine.eval('return loadfile');
        expect(result, isNull);
      });
    });

    group('Reset', () {
      test('reset clears globals', () async {
        engine.setGlobal('beforeReset', 'value');
        await engine.reset();
        expect(engine.hasGlobal('beforeReset'), isFalse);
      });

      test('reset restores engine to ready state', () async {
        await engine.reset();
        expect(engine.state, equals(LuaEngineState.ready));
      });

      test('engine works after reset', () async {
        await engine.reset();
        final result = await engine.eval('return 1 + 1');
        expect(result, equals(2));
      });
    });

    group('Dispose', () {
      test('dispose sets state to disposed', () async {
        final localEngine = LuaEngineDart.create();
        await localEngine.init();
        await localEngine.dispose();

        expect(localEngine.state, equals(LuaEngineState.disposed));
      });
    });

    group('Memory and GC', () {
      test('collectGarbage does not throw', () {
        expect(() => engine.collectGarbage(), returnsNormally);
      });

      test('memoryUsage returns a number', () {
        expect(engine.memoryUsage, isA<int>());
      });
    });

    group('Complex Scenarios', () {
      test('executes complex script with multiple operations', () async {
        await engine.eval('''
          -- Define helper function
          function sum(t)
            local s = 0
            for _, v in ipairs(t) do
              s = s + v
            end
            return s
          end

          -- Create data
          data = {1, 2, 3, 4, 5}
          result = sum(data)
        ''');

        final result = engine.getGlobal('result');
        expect(result, equals(15));
      });

      test('handles nested table structures', () async {
        final result = await engine.eval('''
          return {
            user = {
              name = "Alice",
              age = 25
            },
            settings = {
              theme = "dark"
            }
          }
        ''');

        expect(result, isA<Map>());
        expect(result['user']['name'], equals('Alice'));
        expect(result['settings']['theme'], equals('dark'));
      });

      test('handles closures', () async {
        await engine.eval('''
          function counter()
            local count = 0
            return function()
              count = count + 1
              return count
            end
          end

          myCounter = counter()
        ''');

        final result1 = await engine.eval('return myCounter()');
        final result2 = await engine.eval('return myCounter()');
        final result3 = await engine.eval('return myCounter()');

        expect(result1, equals(1));
        expect(result2, equals(2));
        expect(result3, equals(3));
      });
    });
  });
}
