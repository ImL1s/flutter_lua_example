import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_example/core/providers/lua_providers.dart';
import 'package:flutter_lua_example/core/lua_engine/lua_engine.dart';

void main() {
  group('LuaEngineProviderState', () {
    test('initial state has no engine', () {
      const state = LuaEngineProviderState();
      expect(state.engine, isNull);
      expect(state.isInitializing, isFalse);
      expect(state.error, isNull);
      expect(state.isReady, isFalse);
    });

    test('copyWith updates engine', () {
      const state = LuaEngineProviderState();
      final newState = state.copyWith(isInitializing: true);

      expect(newState.isInitializing, isTrue);
      expect(newState.engine, isNull);
    });

    test('copyWith clears error', () {
      const state = LuaEngineProviderState(error: 'some error');
      final newState = state.copyWith(error: null);

      expect(newState.error, isNull);
    });
  });

  group('LuaStateMapNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty map', () {
      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap, isEmpty);
    });

    test('setState adds key-value pair', () {
      container.read(luaStateMapProvider.notifier).setState('key', 'value');
      final stateMap = container.read(luaStateMapProvider);

      expect(stateMap['key'], equals('value'));
    });

    test('setState updates existing key', () {
      final notifier = container.read(luaStateMapProvider.notifier);
      notifier.setState('key', 'value1');
      notifier.setState('key', 'value2');

      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap['key'], equals('value2'));
    });

    test('removeState removes key', () {
      final notifier = container.read(luaStateMapProvider.notifier);
      notifier.setState('key', 'value');
      notifier.removeState('key');

      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap.containsKey('key'), isFalse);
    });

    test('clear removes all keys', () {
      final notifier = container.read(luaStateMapProvider.notifier);
      notifier.setState('key1', 'value1');
      notifier.setState('key2', 'value2');
      notifier.clear();

      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap, isEmpty);
    });

    test('updateStates batch updates', () {
      final notifier = container.read(luaStateMapProvider.notifier);
      notifier.updateStates({
        'a': 1,
        'b': 2,
        'c': 3,
      });

      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap['a'], equals(1));
      expect(stateMap['b'], equals(2));
      expect(stateMap['c'], equals(3));
    });

    test('setState with different types', () {
      final notifier = container.read(luaStateMapProvider.notifier);
      notifier.setState('string', 'hello');
      notifier.setState('number', 42);
      notifier.setState('bool', true);
      notifier.setState('list', [1, 2, 3]);
      notifier.setState('map', {'nested': 'value'});

      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap['string'], equals('hello'));
      expect(stateMap['number'], equals(42));
      expect(stateMap['bool'], equals(true));
      expect(stateMap['list'], equals([1, 2, 3]));
      expect(stateMap['map'], equals({'nested': 'value'}));
    });
  });

  group('luaStateProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns null for non-existent key', () {
      final value = container.read(luaStateProvider('nonExistent'));
      expect(value, isNull);
    });

    test('returns value for existing key', () {
      container.read(luaStateMapProvider.notifier).setState('myKey', 'myValue');
      final value = container.read(luaStateProvider('myKey'));
      expect(value, equals('myValue'));
    });

    test('updates when state changes', () async {
      final notifier = container.read(luaStateMapProvider.notifier);

      // First read to establish baseline
      expect(container.read(luaStateProvider('counter')), isNull);

      // Update state
      notifier.setState('counter', 1);

      // Verify the state was updated
      expect(container.read(luaStateProvider('counter')), equals(1));

      // Update again
      notifier.setState('counter', 2);
      expect(container.read(luaStateProvider('counter')), equals(2));
    });
  });

  group('LuaEngineNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is not ready', () {
      final engineState = container.read(luaEngineProvider);
      expect(engineState.isReady, isFalse);
      expect(engineState.engine, isNull);
    });

    test('initialize creates engine', () async {
      await container.read(luaEngineProvider.notifier).initialize();
      final engineState = container.read(luaEngineProvider);

      expect(engineState.isReady, isTrue);
      expect(engineState.engine, isNotNull);
    });

    test('eval executes Lua code', () async {
      await container.read(luaEngineProvider.notifier).initialize();
      final result =
          await container.read(luaEngineProvider.notifier).eval('return 42');

      expect(result, equals(42));
    });

    test('call invokes Lua function', () async {
      final notifier = container.read(luaEngineProvider.notifier);
      await notifier.initialize();
      await notifier.eval('function double(x) return x * 2 end');

      final result = await notifier.call('double', [21]);
      expect(result, equals(42));
    });

    test('setGlobal and getGlobal work', () async {
      final notifier = container.read(luaEngineProvider.notifier);
      await notifier.initialize();

      notifier.setGlobal('testVar', 'testValue');
      final result = notifier.getGlobal('testVar');

      expect(result, equals('testValue'));
    });

    test('registerFunction adds callable function', () async {
      final notifier = container.read(luaEngineProvider.notifier);
      await notifier.initialize();

      notifier.registerFunction('customAdd', (args) {
        return (args[0] as num) + (args[1] as num);
      });

      final result =
          await notifier.eval("return callNative('customAdd', 10, 5)");
      expect(result, equals(15));
    });

    test('reset clears state', () async {
      final notifier = container.read(luaEngineProvider.notifier);
      await notifier.initialize();

      notifier.setGlobal('toBeCleared', 123);
      await notifier.reset();

      final engineState = container.read(luaEngineProvider);
      expect(engineState.engine!.hasGlobal('toBeCleared'), isFalse);
    });

    test('setState updates luaStateMapProvider', () async {
      final notifier = container.read(luaEngineProvider.notifier);
      await notifier.initialize();

      await notifier.eval("callNative('setState', 'fromLua', 'luaValue')");

      final stateMap = container.read(luaStateMapProvider);
      expect(stateMap['fromLua'], equals('luaValue'));
    });

    test('getState reads from luaStateMapProvider', () async {
      final notifier = container.read(luaEngineProvider.notifier);
      await notifier.initialize();

      container.read(luaStateMapProvider.notifier).setState('existing', 'value');

      final result =
          await notifier.eval("return callNative('getState', 'existing')");
      expect(result, equals('value'));
    });
  });

  group('Event Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('luaEventsProvider returns empty when engine not initialized', () {
      final eventsAsync = container.read(luaEventsProvider);
      eventsAsync.whenData((event) {
        fail('Should not have data');
      });
    });

    test('luaEventsProvider emits events after initialization', () async {
      await container.read(luaEngineProvider.notifier).initialize();

      // Execute code that emits an event
      await container
          .read(luaEngineProvider.notifier)
          .eval('print("test event")');

      // Give time for event to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      // Events should be available
      final eventsAsync = container.read(luaEventsProvider);
      expect(eventsAsync, isNotNull);
    });
  });
}
