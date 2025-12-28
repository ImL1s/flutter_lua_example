/// Lua 異常基類
class LuaException implements Exception {
  /// 錯誤訊息
  final String message;

  /// 錯誤代碼
  final String? code;

  /// 額外詳情
  final dynamic details;

  /// 堆棧追蹤
  final StackTrace? stackTrace;

  const LuaException(
    this.message, {
    this.code,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('LuaException');
    if (code != null) {
      buffer.write('[$code]');
    }
    buffer.write(': $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}

/// Lua 初始化異常
class LuaInitException extends LuaException {
  const LuaInitException(super.message, {super.code, super.details});
}

/// Lua 執行異常
class LuaExecutionException extends LuaException {
  /// Lua 腳本名稱
  final String? scriptName;

  /// 執行的代碼片段
  final String? luaCode;

  const LuaExecutionException(
    super.message, {
    this.scriptName,
    this.luaCode,
    super.details,
  }) : super(code: 'EXECUTION_ERROR');
}

/// Lua 調用異常
class LuaCallException extends LuaException {
  /// 被調用的函數名
  final String functionName;

  /// 調用參數
  final List<dynamic>? arguments;

  const LuaCallException(
    super.message, {
    required this.functionName,
    this.arguments,
    super.details,
  }) : super(code: 'CALL_ERROR');

  @override
  String toString() {
    return 'LuaCallException: Failed to call "$functionName" - $message';
  }
}

/// Lua 類型轉換異常
class LuaTypeException extends LuaException {
  /// 期望的類型
  final String expectedType;

  /// 實際的類型
  final String actualType;

  const LuaTypeException({
    required this.expectedType,
    required this.actualType,
    String? message,
  }) : super(
          message ?? 'Type mismatch: expected $expectedType, got $actualType',
          code: 'TYPE_ERROR',
        );
}

/// Lua 腳本安全異常
class LuaSecurityException extends LuaException {
  const LuaSecurityException(super.message)
      : super(code: 'SECURITY_ERROR');
}

/// Lua 超時異常
class LuaTimeoutException extends LuaException {
  /// 超時時間（毫秒）
  final int timeoutMs;

  const LuaTimeoutException({
    required this.timeoutMs,
    String? message,
  }) : super(
          message ?? 'Lua execution timed out after ${timeoutMs}ms',
          code: 'TIMEOUT_ERROR',
        );
}
