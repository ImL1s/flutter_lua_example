# Flutter Lua 腳本引擎整合方案 - 需求與架構設計

> 整合 Claude Code、OpenAI Codex、Google Gemini 三方 AI 分析的最終建議

## 一、專案背景與需求

### 1.1 核心需求

| 需求 | 說明 | 優先級 |
|------|------|--------|
| Lua 控制業務邏輯 | UI 模組顯示條件、流程判斷、點擊事件處理、動態規則計算 | P0 |
| 熱更新支持 | 遠程下載 Lua 腳本並執行，無需重新發布應用 | P0 |
| 跨平台支持 | Android、iOS、Web 全平台運行 | P0 |
| 雙向交互 | Flutter ↔ Lua 函數調用與回調 | P0 |
| 狀態管理 | 使用 Riverpod 3.x 管理應用狀態 | P1 |

### 1.2 技術約束

- **iOS 平台**：禁止 JIT，必須使用解釋器模式
- **Web 平台**：不支持 `dart:ffi`，需使用 WASM 或純 Dart
- **App Store 合規**：熱更新不能改變應用主要功能

---

## 二、技術方案比較

### 2.1 三個 AI 的共識點

| 觀點 | Codex | Gemini | Claude |
|------|-------|--------|--------|
| 混合方案性能最佳 | ✅ | ✅ | ✅ |
| 純 Dart 對中小型項目更實際 | ✅ | ✅ 強烈推薦 | ✅ |
| RPC 風格雙向交互 | ✅ | ✅ | ✅ |
| 熱更新有合規風險 | ⚠️ | ⚠️ 詳細分析 | ⚠️ |
| 考慮 Shorebird 替代 | ❌ 未提及 | ✅ 強烈推薦 | ✅ |

### 2.2 方案對比矩陣

| 方案 | 性能 | 跨平台 | 維護成本 | 適用場景 |
|------|------|--------|----------|----------|
| **混合方案** (FFI + WASM) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | 遊戲、高頻計算 |
| **純 Dart** (LuaDardo) | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | UI 邏輯、中小型項目 |
| **Shorebird** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 熱修復、Bug 修復 |
| **SDUI + 表達式引擎** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 運營活動頁面 |

---

## 三、推薦方案

### 3.1 針對本專案的推薦

**首選：純 Dart 方案 (LuaDardo)**

理由：
1. 開發體驗最好，一次編寫到處運行
2. 無原生依賴，不需要配置 NDK 或 Xcode Build Phases
3. Web 零成本支持
4. 對於 UI 邏輯（顯示條件、流程判斷）性能綽綽有餘
5. 與 Riverpod 整合更簡單安全

**備選：混合方案（需要高性能時）**

- 行動端：Lua C + FFI
- Web 端：Wasmoon (WASM) 或 LuaDardo fallback

### 3.2 不推薦的方案

- `flutter_embed_lua`：缺 iOS/Web 支持
- `flutter_lua`：6 年未更新，不兼容 Dart 3

---

## 四、架構設計

### 4.1 LuaEngine 抽象層

```dart
/// Lua 引擎抽象介面
abstract class LuaEngine {
  /// 初始化引擎
  Future<void> init();

  /// 釋放資源
  Future<void> dispose();

  /// 執行 Lua 代碼
  Future<dynamic> eval(String code, {String? chunkName});

  /// 調用 Lua 函數
  Future<dynamic> call(String funcName, List<dynamic> args);

  /// 註冊 Dart 函數供 Lua 調用
  void registerFunction(String name, LuaCallback callback);

  /// 設置全局變量
  void setGlobal(String name, dynamic value);

  /// 獲取全局變量
  dynamic getGlobal(String name);

  /// Lua 事件流（用於回調通知）
  Stream<LuaEvent> get events;
}

/// Lua 回調函數類型
typedef LuaCallback = FutureOr<dynamic> Function(List<dynamic> args);

/// Lua 事件
class LuaEvent {
  final String type;
  final Map<String, dynamic> data;
  LuaEvent(this.type, this.data);
}
```

### 4.2 平台實現

```
lib/
├── lua_engine/
│   ├── lua_engine.dart           # 抽象介面
│   ├── lua_engine_dart.dart      # 純 Dart 實現 (LuaDardo)
│   ├── lua_engine_native.dart    # FFI 實現 (可選)
│   ├── lua_engine_factory.dart   # 工廠方法
│   └── lua_value.dart            # 類型映射
```

### 4.3 Riverpod 整合模式

```dart
/// LuaEngine Provider
final luaEngineProvider = AsyncNotifierProvider<LuaEngineNotifier, LuaEngine>(
  LuaEngineNotifier.new,
);

class LuaEngineNotifier extends AsyncNotifier<LuaEngine> {
  @override
  Future<LuaEngine> build() async {
    final engine = LuaEngineFactory.create();
    await engine.init();

    // 註冊基礎函數
    _registerBaseFunctions(engine);

    // 生命週期管理
    ref.onDispose(() => engine.dispose());

    return engine;
  }

  void _registerBaseFunctions(LuaEngine engine) {
    // setState - 讓 Lua 更新 Riverpod 狀態
    engine.registerFunction('setState', (args) {
      final key = args[0] as String;
      final value = args[1];
      // 根據 key 更新對應的 Provider
      _updateState(key, value);
      return null;
    });

    // getState - 讓 Lua 讀取狀態
    engine.registerFunction('getState', (args) {
      final key = args[0] as String;
      return _readState(key);
    });

    // showToast - UI 交互
    engine.registerFunction('showToast', (args) {
      final message = args[0] as String;
      // 觸發 Toast 顯示
      return null;
    });

    // navigateTo - 頁面導航
    engine.registerFunction('navigateTo', (args) {
      final route = args[0] as String;
      // 執行導航
      return null;
    });
  }
}

/// Lua 事件流 Provider
final luaEventsProvider = StreamProvider<LuaEvent>((ref) {
  final engine = ref.watch(luaEngineProvider).valueOrNull;
  if (engine == null) return const Stream.empty();
  return engine.events;
});
```

### 4.4 雙向交互流程

```
┌─────────────┐                    ┌─────────────┐
│   Flutter   │                    │     Lua     │
│    (UI)     │                    │  (Script)   │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │  1. UI 事件觸發                   │
       │─────────────────────────────────>│
       │     engine.call('onButtonClick') │
       │                                  │
       │  2. Lua 處理邏輯                  │
       │                                  │
       │  3. Lua 回調 Dart                 │
       │<─────────────────────────────────│
       │     callNative('setState', args) │
       │                                  │
       │  4. Riverpod 狀態更新             │
       │                                  │
       │  5. UI 自動重建                   │
       │                                  │
```

---

## 五、熱更新機制

### 5.1 腳本管理

```dart
class ScriptManager {
  final LuaEngine engine;
  final ScriptRepository repository;

  /// 從遠程獲取並更新腳本
  Future<void> updateScripts() async {
    // 1. 檢查版本
    final remoteVersion = await repository.getRemoteVersion();
    final localVersion = await repository.getLocalVersion();

    if (remoteVersion > localVersion) {
      // 2. 下載新腳本
      final scripts = await repository.downloadScripts();

      // 3. 驗證簽名
      if (!await _verifySignature(scripts)) {
        throw SecurityException('腳本簽名驗證失敗');
      }

      // 4. 備份舊腳本 (A/B 切換)
      await repository.backupCurrentScripts();

      // 5. 應用新腳本
      await repository.saveScripts(scripts);

      // 6. 重新載入
      await _reloadScripts(scripts);
    }
  }
}
```

### 5.2 App Store 合規建議

| 行為 | 合規性 | 說明 |
|------|--------|------|
| 修復 Bug | ✅ 安全 | 被視為維護更新 |
| 調整 UI 佈局參數 | ✅ 安全 | 配置同步 |
| A/B 測試邏輯 | ✅ 安全 | 合理的產品優化 |
| 更新遊戲關卡 | ✅ 安全 | 內容更新 |
| 新增未審核功能 | ❌ 危險 | 違反指南 2.5.2 |
| 繞過內購 | ❌ 危險 | 嚴重違規 |

---

## 六、性能測試建議

### 6.1 關鍵指標

| 指標 | 測試方法 | 目標值 |
|------|----------|--------|
| **Interop Overhead** | Dart↔Lua 調用 1000 次 | < 100ms |
| **Memory Footprint** | 載入 50 個腳本實例 | < 50MB |
| **Startup Time** | 引擎初始化到首次執行 | < 500ms |
| **UI 響應延遲** | 複雜表單驗證 (20+ 規則) | < 16ms |

### 6.2 POC 驗證計劃

```dart
// 基準測試範例
Future<void> runBenchmark() async {
  final engine = await LuaEngineFactory.create();
  await engine.init();

  // 1. Interop 測試
  final sw = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    await engine.call('testFunc', [i]);
  }
  print('1000 次調用耗時: ${sw.elapsedMilliseconds}ms');

  // 2. 複雜邏輯測試
  final complexScript = '''
    function validate(data)
      local errors = {}
      if data.name == nil or #data.name < 2 then
        table.insert(errors, "名稱至少2字")
      end
      -- 20+ 驗證規則...
      return errors
    end
  ''';
  await engine.eval(complexScript);

  sw.reset();
  final result = await engine.call('validate', [testData]);
  print('驗證耗時: ${sw.elapsedMilliseconds}ms');
}
```

---

## 七、實現步驟

### Phase 1: 基礎架構 (Week 1-2)

- [ ] 設置專案結構
- [ ] 整合 LuaDardo 依賴
- [ ] 實現 LuaEngine 抽象層
- [ ] 實現 LuaEngineDart (純 Dart 版本)
- [ ] 基礎單元測試

### Phase 2: Riverpod 整合 (Week 3)

- [ ] 實現 LuaEngineProvider
- [ ] 設計狀態映射機制
- [ ] 實現雙向交互函數
- [ ] 整合測試

### Phase 3: 熱更新機制 (Week 4)

- [ ] 實現 ScriptManager
- [ ] 腳本版本控制
- [ ] 簽名驗證
- [ ] A/B 切換機制

### Phase 4: 優化與測試 (Week 5)

- [ ] 性能基準測試
- [ ] 低端設備測試
- [ ] Web 平台驗證
- [ ] 文檔完善

---

## 八、替代方案評估

如果最終決定不使用 Lua，以下是替代選擇：

| 方案 | 優點 | 缺點 | 適用場景 |
|------|------|------|----------|
| **Shorebird** | 原生 Dart 熱修復 | 付費服務 | Bug 修復、微調 |
| **Remote Flutter Widgets** | 完全合規、架構清晰 | 無法處理複雜邏輯 | 運營活動頁面 |
| **QuickJS** | JS 生態大 | 引擎體積大 | 前端團隊 |
| **自訂 DSL** | 安全可控 | 開發成本高 | 特定領域邏輯 |

---

## 九、參考資源

### 文檔連結
- [Riverpod 3.x 官方文檔](https://riverpod.dev)
- [Flutter FFI 指南](https://docs.flutter.dev/platform-integration/android/c-interop)
- [LuaDardo GitHub](https://github.com/ArcticFox1919/lua_dardo)
- [Wasmoon GitHub](https://github.com/ceifa/wasmoon)
- [Shorebird](https://shorebird.dev)

### 相關 Packages
```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  lua_dardo: ^0.0.3  # 純 Dart Lua
  # 可選
  http: ^1.2.0       # 腳本下載
  crypto: ^3.0.0     # 簽名驗證
```

---

*文檔生成時間: 2025-12-29*
*整合來源: Claude Code + OpenAI Codex + Google Gemini*
