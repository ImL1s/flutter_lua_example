/// Lua 值類型枚舉
enum LuaValueType {
  nil,
  boolean,
  number,
  string,
  table,
  function_,
  userdata,
  thread,
}

/// Lua 值包裝類 - 用於 Dart ↔ Lua 類型映射
class LuaValue {
  /// 值類型
  final LuaValueType type;

  /// 原始值
  final dynamic _value;

  const LuaValue._(this.type, this._value);

  /// 創建 nil 值
  static const LuaValue nil = LuaValue._(LuaValueType.nil, null);

  /// 從布爾值創建
  factory LuaValue.fromBool(bool value) {
    return LuaValue._(LuaValueType.boolean, value);
  }

  /// 從數字創建
  factory LuaValue.fromNumber(num value) {
    return LuaValue._(LuaValueType.number, value.toDouble());
  }

  /// 從字符串創建
  factory LuaValue.fromString(String value) {
    return LuaValue._(LuaValueType.string, value);
  }

  /// 從 Map 創建（對應 Lua table）
  factory LuaValue.fromTable(Map<dynamic, dynamic> value) {
    return LuaValue._(LuaValueType.table, value);
  }

  /// 從 List 創建（對應 Lua array table）
  factory LuaValue.fromList(List<dynamic> value) {
    // 轉換為 1-based index 的 Map（Lua 風格）
    final table = <dynamic, dynamic>{};
    for (var i = 0; i < value.length; i++) {
      table[i + 1] = value[i];
    }
    return LuaValue._(LuaValueType.table, table);
  }

  /// 從任意 Dart 值自動推斷類型
  factory LuaValue.from(dynamic value) {
    if (value == null) return LuaValue.nil;
    if (value is bool) return LuaValue.fromBool(value);
    if (value is num) return LuaValue.fromNumber(value);
    if (value is String) return LuaValue.fromString(value);
    if (value is List) return LuaValue.fromList(value);
    if (value is Map) return LuaValue.fromTable(value);
    if (value is LuaValue) return value;

    // 嘗試轉換為字符串
    return LuaValue.fromString(value.toString());
  }

  /// 是否為 nil
  bool get isNil => type == LuaValueType.nil;

  /// 是否為布爾值
  bool get isBool => type == LuaValueType.boolean;

  /// 是否為數字
  bool get isNumber => type == LuaValueType.number;

  /// 是否為字符串
  bool get isString => type == LuaValueType.string;

  /// 是否為 table
  bool get isTable => type == LuaValueType.table;

  /// 獲取布爾值
  bool? get asBool => isBool ? _value as bool : null;

  /// 獲取數字值
  double? get asNumber => isNumber ? _value as double : null;

  /// 獲取整數值
  int? get asInt => isNumber ? (_value as double).toInt() : null;

  /// 獲取字符串值
  String? get asString => isString ? _value as String : null;

  /// 獲取 table 值
  Map<dynamic, dynamic>? get asTable =>
      isTable ? _value as Map<dynamic, dynamic> : null;

  /// 獲取 Dart 原生值
  dynamic get value => _value;

  /// 轉換為 Dart 原生類型
  dynamic toDart() {
    switch (type) {
      case LuaValueType.nil:
        return null;
      case LuaValueType.boolean:
        return _value as bool;
      case LuaValueType.number:
        return _value as double;
      case LuaValueType.string:
        return _value as String;
      case LuaValueType.table:
        final map = _value as Map<dynamic, dynamic>;
        // 檢查是否為數組形式的 table
        if (_isArrayTable(map)) {
          return _tableToList(map);
        }
        return _convertTableToDart(map);
      default:
        return _value;
    }
  }

  /// 檢查是否為數組形式的 table
  static bool _isArrayTable(Map<dynamic, dynamic> table) {
    if (table.isEmpty) return true;
    final keys = table.keys.toList();
    if (!keys.every((k) => k is int || (k is double && k == k.toInt()))) {
      return false;
    }
    final intKeys = keys.map((k) => k is int ? k : (k as double).toInt()).toList()
      ..sort();
    for (var i = 0; i < intKeys.length; i++) {
      if (intKeys[i] != i + 1) return false;
    }
    return true;
  }

  /// 將數組 table 轉換為 List
  static List<dynamic> _tableToList(Map<dynamic, dynamic> table) {
    if (table.isEmpty) return [];
    final maxKey = table.keys
        .map((k) => k is int ? k : (k as double).toInt())
        .reduce((a, b) => a > b ? a : b);
    final list = <dynamic>[];
    for (var i = 1; i <= maxKey; i++) {
      final value = table[i] ?? table[i.toDouble()];
      list.add(_convertValue(value));
    }
    return list;
  }

  /// 遞歸轉換 table 為 Dart Map
  static Map<String, dynamic> _convertTableToDart(Map<dynamic, dynamic> table) {
    return table.map((key, value) {
      final dartKey = key.toString();
      final dartValue = _convertValue(value);
      return MapEntry(dartKey, dartValue);
    });
  }

  /// 轉換單個值
  static dynamic _convertValue(dynamic value) {
    if (value == null) return null;
    if (value is bool || value is num || value is String) return value;
    if (value is Map<dynamic, dynamic>) {
      if (_isArrayTable(value)) {
        return _tableToList(value);
      }
      return _convertTableToDart(value);
    }
    if (value is LuaValue) return value.toDart();
    return value;
  }

  @override
  String toString() => 'LuaValue($type: $_value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LuaValue) return false;
    return type == other.type && _value == other._value;
  }

  @override
  int get hashCode => Object.hash(type, _value);
}
