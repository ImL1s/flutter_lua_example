/// Lua 事件類型枚舉
enum LuaEventType {
  /// 狀態變更事件
  stateChange,

  /// 日誌事件
  log,

  /// 導航事件
  navigation,

  /// Toast 顯示事件
  toast,

  /// 錯誤事件
  error,

  /// 自定義事件
  custom,
}

/// Lua 事件類 - 用於 Lua 到 Flutter 的回調通知
class LuaEvent {
  /// 事件類型
  final LuaEventType type;

  /// 事件數據
  final Map<String, dynamic> data;

  /// 事件時間戳
  final DateTime timestamp;

  LuaEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 創建狀態變更事件
  factory LuaEvent.stateChange(String key, dynamic value) {
    return LuaEvent(
      type: LuaEventType.stateChange,
      data: {'key': key, 'value': value},
    );
  }

  /// 創建日誌事件
  factory LuaEvent.log(String level, String message) {
    return LuaEvent(
      type: LuaEventType.log,
      data: {'level': level, 'message': message},
    );
  }

  /// 創建導航事件
  factory LuaEvent.navigation(String route, [Map<String, dynamic>? params]) {
    return LuaEvent(
      type: LuaEventType.navigation,
      data: {'route': route, 'params': params ?? {}},
    );
  }

  /// 創建 Toast 事件
  factory LuaEvent.toast(String message, {String? type}) {
    return LuaEvent(
      type: LuaEventType.toast,
      data: {'message': message, 'type': type ?? 'info'},
    );
  }

  /// 創建錯誤事件
  factory LuaEvent.error(String message, {String? code, dynamic details}) {
    return LuaEvent(
      type: LuaEventType.error,
      data: {'message': message, 'code': code, 'details': details},
    );
  }

  /// 創建自定義事件
  factory LuaEvent.custom(String name, Map<String, dynamic> data) {
    return LuaEvent(
      type: LuaEventType.custom,
      data: {'name': name, ...data},
    );
  }

  @override
  String toString() => 'LuaEvent(type: $type, data: $data)';
}
