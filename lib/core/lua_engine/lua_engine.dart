import 'dart:async';

import 'lua_event.dart';

export 'lua_event.dart';
export 'lua_exception.dart';
export 'lua_value.dart';

/// Lua 回調函數類型
/// 接收參數列表，返回值可以是同步或異步
typedef LuaCallback = FutureOr<dynamic> Function(List<dynamic> args);

/// Lua 引擎狀態
enum LuaEngineState {
  /// 未初始化
  uninitialized,

  /// 初始化中
  initializing,

  /// 已就緒
  ready,

  /// 執行中
  executing,

  /// 已釋放
  disposed,

  /// 錯誤狀態
  error,
}

/// Lua 引擎抽象介面
///
/// 定義了與 Lua 腳本引擎交互的標準接口。
/// 具體實現可以是純 Dart (LuaDardo)、FFI (原生 Lua) 或 WASM。
abstract class LuaEngine {
  /// 獲取引擎當前狀態
  LuaEngineState get state;

  /// 引擎是否已就緒
  bool get isReady => state == LuaEngineState.ready;

  /// 初始化引擎
  ///
  /// 必須在使用其他方法之前調用。
  /// 可選參數：
  /// - [sandboxed] 是否啟用沙箱模式（移除危險函數）
  /// - [memoryLimit] 內存限制（字節），null 表示無限制
  Future<void> init({
    bool sandboxed = true,
    int? memoryLimit,
  });

  /// 釋放資源
  ///
  /// 調用後引擎將不可再使用
  Future<void> dispose();

  /// 執行 Lua 代碼
  ///
  /// [code] 要執行的 Lua 代碼字符串
  /// [chunkName] 代碼塊名稱，用於錯誤追蹤
  ///
  /// 返回執行結果，如果代碼沒有返回值則返回 null
  Future<dynamic> eval(String code, {String? chunkName});

  /// 執行 Lua 文件
  ///
  /// [path] Lua 腳本文件路徑
  Future<dynamic> evalFile(String path);

  /// 調用 Lua 全局函數
  ///
  /// [funcName] 函數名稱
  /// [args] 參數列表
  ///
  /// 返回函數返回值
  Future<dynamic> call(String funcName, [List<dynamic> args = const []]);

  /// 調用 Lua table 中的方法
  ///
  /// [tableName] table 名稱
  /// [methodName] 方法名稱
  /// [args] 參數列表
  Future<dynamic> callMethod(
    String tableName,
    String methodName, [
    List<dynamic> args = const [],
  ]);

  /// 註冊 Dart 函數供 Lua 調用
  ///
  /// [name] 在 Lua 中的函數名
  /// [callback] Dart 回調函數
  void registerFunction(String name, LuaCallback callback);

  /// 批量註冊函數
  void registerFunctions(Map<String, LuaCallback> functions) {
    functions.forEach(registerFunction);
  }

  /// 移除已註冊的函數
  void unregisterFunction(String name);

  /// 設置全局變量
  ///
  /// [name] 變量名
  /// [value] 值（會自動轉換為 Lua 類型）
  void setGlobal(String name, dynamic value);

  /// 獲取全局變量
  ///
  /// [name] 變量名
  /// 返回值會自動轉換為 Dart 類型
  dynamic getGlobal(String name);

  /// 檢查全局變量是否存在
  bool hasGlobal(String name);

  /// 設置 table 字段值
  ///
  /// [tableName] table 名稱
  /// [key] 字段鍵
  /// [value] 字段值
  void setTableField(String tableName, String key, dynamic value);

  /// 獲取 table 字段值
  ///
  /// [tableName] table 名稱
  /// [key] 字段鍵
  dynamic getTableField(String tableName, String key);

  /// Lua 事件流
  ///
  /// 用於接收 Lua 發出的事件（狀態變更、日誌、導航等）
  Stream<LuaEvent> get events;

  /// 發送事件（供內部使用）
  void emitEvent(LuaEvent event);

  /// 重置引擎狀態
  ///
  /// 清除所有全局變量和已註冊的函數，恢復到初始狀態
  Future<void> reset();

  /// 獲取引擎信息
  Map<String, dynamic> get engineInfo;

  /// 執行垃圾回收
  void collectGarbage();

  /// 獲取當前內存使用量（字節）
  int get memoryUsage;
}

/// LuaEngine 工廠方法
///
/// 根據平台自動選擇最佳實現
abstract class LuaEngineFactory {
  /// 創建 LuaEngine 實例
  ///
  /// 目前使用純 Dart 實現 (LuaDardo)
  /// 未來可根據平台選擇 FFI 或 WASM 實現
  static LuaEngine create() {
    // TODO: 根據平台返回不同實現
    // if (kIsWeb) return LuaEngineWasm();
    // if (Platform.isAndroid || Platform.isIOS) return LuaEngineNative();
    throw UnimplementedError(
      'Use LuaEngineDart.create() directly until factory is fully implemented',
    );
  }
}
