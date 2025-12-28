import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lua_engine/lua_engine.dart';
import '../lua_engine/lua_engine_dart.dart';

/// LuaEngine Provider 狀態（區別於 lua_engine.dart 中的 LuaEngineState）
class LuaEngineProviderState {
  final LuaEngine? engine;
  final bool isInitializing;
  final String? error;

  const LuaEngineProviderState({
    this.engine,
    this.isInitializing = false,
    this.error,
  });

  bool get isReady => engine?.isReady ?? false;

  LuaEngineProviderState copyWith({
    LuaEngine? engine,
    bool? isInitializing,
    String? error,
  }) {
    return LuaEngineProviderState(
      engine: engine ?? this.engine,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
    );
  }
}

/// LuaEngine Notifier
class LuaEngineNotifier extends Notifier<LuaEngineProviderState> {
  @override
  LuaEngineProviderState build() {
    return const LuaEngineProviderState();
  }

  /// 初始化 Lua 引擎
  Future<void> initialize({bool sandboxed = true}) async {
    if (state.isInitializing || state.isReady) return;

    state = state.copyWith(isInitializing: true, error: null);

    try {
      final engine = LuaEngineDart.create();
      await engine.init(sandboxed: sandboxed);

      // 註冊基礎函數
      _registerBaseFunctions(engine);

      state = LuaEngineProviderState(engine: engine);

      // 設置生命週期管理
      ref.onDispose(() {
        engine.dispose();
      });
    } catch (e) {
      state = LuaEngineProviderState(error: e.toString());
    }
  }

  /// 註冊基礎函數
  void _registerBaseFunctions(LuaEngine engine) {
    // setState - 讓 Lua 更新狀態
    engine.registerFunction('setState', (args) {
      if (args.length >= 2) {
        final key = args[0].toString();
        final value = args[1];
        ref.read(luaStateMapProvider.notifier).setState(key, value);
      }
      return null;
    });

    // getState - 讓 Lua 讀取狀態
    engine.registerFunction('getState', (args) {
      if (args.isNotEmpty) {
        final key = args[0].toString();
        return ref.read(luaStateMapProvider)[key];
      }
      return null;
    });

    // showToast - Toast 顯示
    engine.registerFunction('showToast', (args) {
      if (args.isNotEmpty) {
        final message = args[0].toString();
        final type = args.length > 1 ? args[1].toString() : 'info';
        engine.emitEvent(LuaEvent.toast(message, type: type));
      }
      return null;
    });

    // navigateTo - 頁面導航
    engine.registerFunction('navigateTo', (args) {
      if (args.isNotEmpty) {
        final route = args[0].toString();
        final params = args.length > 1 && args[1] is Map
            ? Map<String, dynamic>.from(args[1] as Map)
            : <String, dynamic>{};
        engine.emitEvent(LuaEvent.navigation(route, params));
      }
      return null;
    });

    // log - 日誌記錄
    engine.registerFunction('log', (args) {
      if (args.isNotEmpty) {
        final level = args.length > 1 ? args[0].toString() : 'info';
        final message = args.length > 1 ? args[1].toString() : args[0].toString();
        engine.emitEvent(LuaEvent.log(level, message));
      }
      return null;
    });

    // delay - 延遲執行（用於動畫等）
    engine.registerFunction('delay', (args) async {
      final ms = args.isNotEmpty ? (args[0] as num).toInt() : 0;
      await Future.delayed(Duration(milliseconds: ms));
      return null;
    });
  }

  /// 執行 Lua 代碼
  Future<dynamic> eval(String code, {String? chunkName}) async {
    final engine = state.engine;
    if (engine == null) throw LuaException('Engine not initialized');
    return engine.eval(code, chunkName: chunkName);
  }

  /// 調用 Lua 函數
  Future<dynamic> call(String funcName, [List<dynamic> args = const []]) async {
    final engine = state.engine;
    if (engine == null) throw LuaException('Engine not initialized');
    return engine.call(funcName, args);
  }

  /// 設置全局變量
  void setGlobal(String name, dynamic value) {
    final engine = state.engine;
    if (engine == null) throw LuaException('Engine not initialized');
    engine.setGlobal(name, value);
  }

  /// 獲取全局變量
  dynamic getGlobal(String name) {
    final engine = state.engine;
    if (engine == null) throw LuaException('Engine not initialized');
    return engine.getGlobal(name);
  }

  /// 註冊自定義函數
  void registerFunction(String name, LuaCallback callback) {
    final engine = state.engine;
    if (engine == null) throw LuaException('Engine not initialized');
    engine.registerFunction(name, callback);
  }

  /// 重置引擎
  Future<void> reset() async {
    final engine = state.engine;
    if (engine == null) return;
    await engine.reset();
    _registerBaseFunctions(engine);
  }
}

/// LuaEngine Provider
final luaEngineProvider =
    NotifierProvider<LuaEngineNotifier, LuaEngineProviderState>(LuaEngineNotifier.new);

/// Lua 狀態映射 Notifier
class LuaStateMapNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {};
  }

  /// 設置狀態
  void setState(String key, dynamic value) {
    state = {...state, key: value};
  }

  /// 移除狀態
  void removeState(String key) {
    final newState = Map<String, dynamic>.from(state);
    newState.remove(key);
    state = newState;
  }

  /// 清除所有狀態
  void clear() {
    state = {};
  }

  /// 批量更新狀態
  void updateStates(Map<String, dynamic> updates) {
    state = {...state, ...updates};
  }
}

/// Lua 狀態映射 Provider
final luaStateMapProvider =
    NotifierProvider<LuaStateMapNotifier, Map<String, dynamic>>(
  LuaStateMapNotifier.new,
);

/// 獲取單個狀態值的 Provider
final luaStateProvider = Provider.family<dynamic, String>((ref, key) {
  final stateMap = ref.watch(luaStateMapProvider);
  return stateMap[key];
});

/// Lua 事件流 Provider
final luaEventsProvider = StreamProvider<LuaEvent>((ref) {
  final engineState = ref.watch(luaEngineProvider);
  final engine = engineState.engine;

  if (engine == null) {
    return const Stream.empty();
  }

  return engine.events;
});

/// 便捷的 Provider - 用於獲取 Toast 事件
final luaToastEventsProvider = StreamProvider<LuaEvent>((ref) {
  final eventsAsync = ref.watch(luaEventsProvider);

  return eventsAsync.maybeWhen(
    data: (event) {
      final engine = ref.read(luaEngineProvider).engine;
      if (engine == null) return const Stream.empty();

      return engine.events.where((e) => e.type == LuaEventType.toast);
    },
    orElse: () => const Stream.empty(),
  );
});

/// 便捷的 Provider - 用於獲取導航事件
final luaNavigationEventsProvider = StreamProvider<LuaEvent>((ref) {
  final eventsAsync = ref.watch(luaEventsProvider);

  return eventsAsync.maybeWhen(
    data: (event) {
      final engine = ref.read(luaEngineProvider).engine;
      if (engine == null) return const Stream.empty();

      return engine.events.where((e) => e.type == LuaEventType.navigation);
    },
    orElse: () => const Stream.empty(),
  );
});

/// 便捷的 Provider - 用於獲取日誌事件
final luaLogEventsProvider = StreamProvider<LuaEvent>((ref) {
  final engine = ref.read(luaEngineProvider).engine;
  if (engine == null) return const Stream.empty();

  return engine.events.where((e) => e.type == LuaEventType.log);
});
