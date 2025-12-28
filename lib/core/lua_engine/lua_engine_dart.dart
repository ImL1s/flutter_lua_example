import 'dart:async';
import 'dart:io';

import 'package:lua_dardo/lua.dart';

import 'lua_engine.dart';

/// 純 Dart 實現的 Lua 引擎（基於 LuaDardo）
///
/// 使用 LuaDardo 庫實現 Lua 5.3 虛擬機。
/// 優點：跨平台一致、無原生依賴、Web 支持。
class LuaEngineDart implements LuaEngine {
  /// Lua 狀態機
  LuaState? _state;

  /// 引擎狀態
  LuaEngineState _engineState = LuaEngineState.uninitialized;

  /// 事件控制器
  final StreamController<LuaEvent> _eventController =
      StreamController<LuaEvent>.broadcast();

  /// 已註冊的 Dart 回調函數
  final Map<String, LuaCallback> _registeredCallbacks = {};

  /// 是否啟用沙箱模式
  bool _sandboxed = true;

  @override
  LuaEngineState get state => _engineState;

  @override
  bool get isReady => _engineState == LuaEngineState.ready;

  @override
  Stream<LuaEvent> get events => _eventController.stream;

  @override
  Map<String, dynamic> get engineInfo => {
        'name': 'LuaDardo',
        'version': '0.0.5',
        'luaVersion': '5.3',
        'platform': 'Dart',
        'sandboxed': _sandboxed,
      };

  @override
  int get memoryUsage {
    // LuaDardo 沒有直接的內存統計 API
    // 返回估計值
    return 0;
  }

  /// 創建 LuaEngineDart 實例
  factory LuaEngineDart.create() {
    return LuaEngineDart._();
  }

  LuaEngineDart._();

  @override
  Future<void> init({
    bool sandboxed = true,
    int? memoryLimit,
  }) async {
    if (_engineState != LuaEngineState.uninitialized) {
      throw LuaInitException('Engine already initialized');
    }

    _engineState = LuaEngineState.initializing;
    _sandboxed = sandboxed;

    try {
      // 創建 Lua 狀態機
      _state = LuaState.newState();

      // 載入標準庫
      _state!.openLibs();

      // 如果啟用沙箱，移除危險函數
      if (sandboxed) {
        _applySandbox();
      }

      // 註冊內部輔助函數
      _registerInternalFunctions();

      _engineState = LuaEngineState.ready;
    } catch (e, stackTrace) {
      _engineState = LuaEngineState.error;
      throw LuaInitException(
        'Failed to initialize Lua engine: $e',
        details: stackTrace.toString(),
      );
    }
  }

  /// 應用沙箱限制
  void _applySandbox() {
    // 移除危險的全局函數和庫
    final dangerousFunctions = [
      'os',          // 操作系統命令
      'io',          // 文件 I/O
      'debug',       // 調試功能
      'dofile',      // 執行文件
      'loadfile',    // 載入文件
      'load',        // 動態載入代碼（部分限制）
    ];

    for (final funcName in dangerousFunctions) {
      _state!.pushNil();
      _state!.setGlobal(funcName);
    }

    // 註入安全的 print 替代
    _state!.pushDartFunction(_safePrint);
    _state!.setGlobal('print');
  }

  /// 安全的 print 實現
  int _safePrint(LuaState ls) {
    final nargs = ls.getTop();
    final parts = <String>[];

    for (var i = 1; i <= nargs; i++) {
      final str = ls.toStr(i) ?? 'nil';
      parts.add(str);
    }

    final message = parts.join('\t');

    // 發送日誌事件
    emitEvent(LuaEvent.log('info', message));

    return 0;
  }

  /// 註冊內部輔助函數
  void _registerInternalFunctions() {
    // 註冊 callNative 函數供 Lua 調用 Dart
    _state!.pushDartFunction(_callNativeHandler);
    _state!.setGlobal('callNative');

    // 註冊 emit 函數供 Lua 發送事件
    _state!.pushDartFunction(_emitEventHandler);
    _state!.setGlobal('emit');
  }

  /// Lua 調用 Dart 的處理器
  int _callNativeHandler(LuaState ls) {
    final funcName = ls.checkString(1);
    if (funcName == null) {
      ls.pushNil();
      ls.pushString('Function name is required');
      return 2;
    }

    final callback = _registeredCallbacks[funcName];
    if (callback == null) {
      ls.pushNil();
      ls.pushString('Function not found: $funcName');
      return 2;
    }

    // 收集參數
    final nargs = ls.getTop();
    final args = <dynamic>[];
    for (var i = 2; i <= nargs; i++) {
      args.add(_getStackValue(ls, i));
    }

    try {
      // 調用回調
      final result = callback(args);

      // 處理異步結果
      if (result is Future) {
        // 對於異步操作，我們無法直接返回結果
        // 先返回 nil，結果通過事件發送
        result.then((value) {
          emitEvent(LuaEvent.custom('callbackResult', {
            'function': funcName,
            'result': value,
          }));
        }).catchError((error) {
          emitEvent(LuaEvent.error(error.toString(), code: 'CALLBACK_ERROR'));
        });
        ls.pushNil();
        return 1;
      }

      // 同步結果
      _pushValue(ls, result);
      return 1;
    } catch (e) {
      ls.pushNil();
      ls.pushString('Callback error: $e');
      return 2;
    }
  }

  /// Lua 發送事件的處理器
  int _emitEventHandler(LuaState ls) {
    final eventType = ls.checkString(1);
    if (eventType == null) {
      return 0;
    }

    // 獲取事件數據
    Map<String, dynamic> data = {};
    if (ls.getTop() >= 2 && ls.isTable(2)) {
      data = _tableToMap(ls, 2);
    }

    // 根據事件類型發送
    switch (eventType) {
      case 'stateChange':
        emitEvent(LuaEvent.stateChange(
          data['key']?.toString() ?? '',
          data['value'],
        ));
        break;
      case 'toast':
        emitEvent(LuaEvent.toast(
          data['message']?.toString() ?? '',
          type: data['type']?.toString(),
        ));
        break;
      case 'navigate':
        emitEvent(LuaEvent.navigation(
          data['route']?.toString() ?? '',
          data['params'] as Map<String, dynamic>?,
        ));
        break;
      case 'log':
        emitEvent(LuaEvent.log(
          data['level']?.toString() ?? 'info',
          data['message']?.toString() ?? '',
        ));
        break;
      default:
        emitEvent(LuaEvent.custom(eventType, data));
    }

    return 0;
  }

  @override
  Future<void> dispose() async {
    if (_engineState == LuaEngineState.disposed) return;

    _engineState = LuaEngineState.disposed;
    _registeredCallbacks.clear();
    _state = null;

    await _eventController.close();
  }

  @override
  Future<dynamic> eval(String code, {String? chunkName}) async {
    _ensureReady();

    try {
      _engineState = LuaEngineState.executing;

      // 載入代碼
      final loadResult = _state!.loadString(code);
      if (loadResult != ThreadStatus.luaOk) {
        final error = _state!.toStr(-1) ?? 'Unknown error';
        _state!.pop(1);
        throw LuaExecutionException(
          error,
          scriptName: chunkName,
          luaCode: code,
        );
      }

      // 執行代碼
      final callResult = _state!.pCall(0, 1, 0);
      if (callResult != ThreadStatus.luaOk) {
        final error = _state!.toStr(-1) ?? 'Unknown error';
        _state!.pop(1);
        throw LuaExecutionException(
          error,
          scriptName: chunkName,
          luaCode: code,
        );
      }

      // 獲取返回值
      final result = _getStackValue(_state!, -1);
      _state!.pop(1);

      _engineState = LuaEngineState.ready;
      return result;
    } catch (e) {
      _engineState = LuaEngineState.ready;
      if (e is LuaException) rethrow;
      throw LuaExecutionException(
        e.toString(),
        scriptName: chunkName,
        luaCode: code,
      );
    }
  }

  @override
  Future<dynamic> evalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw LuaExecutionException('File not found: $path');
    }

    final code = await file.readAsString();
    return eval(code, chunkName: path);
  }

  @override
  Future<dynamic> call(String funcName, [List<dynamic> args = const []]) async {
    _ensureReady();

    try {
      _engineState = LuaEngineState.executing;

      // 獲取函數
      _state!.getGlobal(funcName);
      if (!_state!.isFunction(-1)) {
        _state!.pop(1);
        throw LuaCallException(
          'Not a function',
          functionName: funcName,
        );
      }

      // 壓入參數
      for (final arg in args) {
        _pushValue(_state!, arg);
      }

      // 調用函數
      final result = _state!.pCall(args.length, 1, 0);
      if (result != ThreadStatus.luaOk) {
        final error = _state!.toStr(-1) ?? 'Unknown error';
        _state!.pop(1);
        throw LuaCallException(
          error,
          functionName: funcName,
          arguments: args,
        );
      }

      // 獲取返回值
      final returnValue = _getStackValue(_state!, -1);
      _state!.pop(1);

      _engineState = LuaEngineState.ready;
      return returnValue;
    } catch (e) {
      _engineState = LuaEngineState.ready;
      if (e is LuaException) rethrow;
      throw LuaCallException(
        e.toString(),
        functionName: funcName,
        arguments: args,
      );
    }
  }

  @override
  Future<dynamic> callMethod(
    String tableName,
    String methodName, [
    List<dynamic> args = const [],
  ]) async {
    _ensureReady();

    try {
      _engineState = LuaEngineState.executing;

      // 獲取 table
      _state!.getGlobal(tableName);
      if (!_state!.isTable(-1)) {
        _state!.pop(1);
        throw LuaCallException(
          'Not a table',
          functionName: '$tableName.$methodName',
        );
      }

      // 獲取方法
      _state!.getField(-1, methodName);
      if (!_state!.isFunction(-1)) {
        _state!.pop(2);
        throw LuaCallException(
          'Not a function',
          functionName: '$tableName.$methodName',
        );
      }

      // 壓入 self (table)
      _state!.pushValue(-2);

      // 壓入其他參數
      for (final arg in args) {
        _pushValue(_state!, arg);
      }

      // 調用方法（包含 self 參數）
      final result = _state!.pCall(args.length + 1, 1, 0);
      if (result != ThreadStatus.luaOk) {
        final error = _state!.toStr(-1) ?? 'Unknown error';
        _state!.pop(2); // pop error and table
        throw LuaCallException(
          error,
          functionName: '$tableName:$methodName',
          arguments: args,
        );
      }

      // 獲取返回值
      final returnValue = _getStackValue(_state!, -1);
      _state!.pop(2); // pop result and table

      _engineState = LuaEngineState.ready;
      return returnValue;
    } catch (e) {
      _engineState = LuaEngineState.ready;
      if (e is LuaException) rethrow;
      throw LuaCallException(
        e.toString(),
        functionName: '$tableName:$methodName',
        arguments: args,
      );
    }
  }

  @override
  void registerFunction(String name, LuaCallback callback) {
    _registeredCallbacks[name] = callback;
  }

  @override
  void registerFunctions(Map<String, LuaCallback> functions) {
    functions.forEach(registerFunction);
  }

  @override
  void unregisterFunction(String name) {
    _registeredCallbacks.remove(name);
  }

  @override
  void setGlobal(String name, dynamic value) {
    _ensureReady();
    _pushValue(_state!, value);
    _state!.setGlobal(name);
  }

  @override
  dynamic getGlobal(String name) {
    _ensureReady();
    _state!.getGlobal(name);
    final value = _getStackValue(_state!, -1);
    _state!.pop(1);
    return value;
  }

  @override
  bool hasGlobal(String name) {
    _ensureReady();
    _state!.getGlobal(name);
    final isNil = _state!.isNil(-1);
    _state!.pop(1);
    return !isNil;
  }

  @override
  void setTableField(String tableName, String key, dynamic value) {
    _ensureReady();
    _state!.getGlobal(tableName);
    if (!_state!.isTable(-1)) {
      _state!.pop(1);
      // 如果 table 不存在，創建新的
      _state!.newTable();
    }
    _pushValue(_state!, value);
    _state!.setField(-2, key);
    _state!.setGlobal(tableName);
  }

  @override
  dynamic getTableField(String tableName, String key) {
    _ensureReady();
    _state!.getGlobal(tableName);
    if (!_state!.isTable(-1)) {
      _state!.pop(1);
      return null;
    }
    _state!.getField(-1, key);
    final value = _getStackValue(_state!, -1);
    _state!.pop(2);
    return value;
  }

  @override
  void emitEvent(LuaEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  @override
  Future<void> reset() async {
    if (_engineState == LuaEngineState.disposed) {
      throw LuaException('Cannot reset disposed engine');
    }

    // 重新初始化
    _state = LuaState.newState();
    _state!.openLibs();

    if (_sandboxed) {
      _applySandbox();
    }

    _registerInternalFunctions();
    _engineState = LuaEngineState.ready;
  }

  @override
  void collectGarbage() {
    _ensureReady();
    // LuaDardo 會自動處理 GC
    // 這裡調用 Lua 的 collectgarbage 函數
    _state!.getGlobal('collectgarbage');
    if (_state!.isFunction(-1)) {
      _state!.pCall(0, 0, 0);
    } else {
      _state!.pop(1);
    }
  }

  /// 確保引擎已就緒
  void _ensureReady() {
    if (_engineState != LuaEngineState.ready &&
        _engineState != LuaEngineState.executing) {
      throw LuaException(
        'Engine not ready. Current state: $_engineState',
        code: 'NOT_READY',
      );
    }
    if (_state == null) {
      throw LuaException('Lua state is null', code: 'NULL_STATE');
    }
  }

  /// 將 Dart 值壓入 Lua 棧
  void _pushValue(LuaState ls, dynamic value) {
    if (value == null) {
      ls.pushNil();
    } else if (value is bool) {
      ls.pushBoolean(value);
    } else if (value is int) {
      ls.pushInteger(value);
    } else if (value is double) {
      ls.pushNumber(value);
    } else if (value is String) {
      ls.pushString(value);
    } else if (value is List) {
      _pushList(ls, value);
    } else if (value is Map) {
      _pushMap(ls, value);
    } else {
      // 其他類型轉為字符串
      ls.pushString(value.toString());
    }
  }

  /// 將 List 壓入棧（作為 Lua array table）
  void _pushList(LuaState ls, List<dynamic> list) {
    ls.newTable();
    for (var i = 0; i < list.length; i++) {
      ls.pushInteger(i + 1); // Lua 數組從 1 開始
      _pushValue(ls, list[i]);
      ls.setTable(-3);
    }
  }

  /// 將 Map 壓入棧（作為 Lua table）
  void _pushMap(LuaState ls, Map<dynamic, dynamic> map) {
    ls.newTable();
    map.forEach((key, value) {
      _pushValue(ls, key);
      _pushValue(ls, value);
      ls.setTable(-3);
    });
  }

  /// 從 Lua 棧獲取值
  dynamic _getStackValue(LuaState ls, int index) {
    if (ls.isNil(index)) {
      return null;
    } else if (ls.isBoolean(index)) {
      return ls.toBoolean(index);
    } else if (ls.isInteger(index)) {
      return ls.toInteger(index);
    } else if (ls.isNumber(index)) {
      return ls.toNumber(index);
    } else if (ls.isString(index)) {
      return ls.toStr(index);
    } else if (ls.isTable(index)) {
      return _tableToMap(ls, index);
    } else if (ls.isFunction(index)) {
      return '<function>';
    }
    return null;
  }

  /// 將 Lua table 轉換為 Dart Map
  Map<String, dynamic> _tableToMap(LuaState ls, int index) {
    final map = <String, dynamic>{};

    // 確保使用絕對索引
    final absIndex = index > 0 ? index : ls.getTop() + index + 1;

    ls.pushNil();
    while (ls.next(absIndex)) {
      final key = _getStackValue(ls, -2);
      final value = _getStackValue(ls, -1);

      if (key != null) {
        map[key.toString()] = value;
      }

      ls.pop(1); // 彈出 value，保留 key 用於下次迭代
    }

    return map;
  }
}
