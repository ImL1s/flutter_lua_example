# Flutter Lua Example - 開發 TODO

## 專案實施檢查清單

### Phase 1: 基礎架構 (Week 1-2)

#### 專案設置
- [ ] 初始化 Flutter 專案
- [ ] 配置 `pubspec.yaml` 依賴
  ```yaml
  dependencies:
    flutter_riverpod: ^3.0.0
    lua_dardo: ^0.0.3
    http: ^1.2.0
    crypto: ^3.0.3
    path_provider: ^2.1.0
  ```
- [ ] 建立目錄結構
  ```
  lib/
  ├── core/
  │   ├── lua_engine/
  │   ├── providers/
  │   └── utils/
  ├── features/
  │   └── demo/
  └── main.dart
  ```

#### LuaEngine 抽象層
- [ ] 創建 `lua_engine.dart` - 抽象介面
- [ ] 創建 `lua_value.dart` - 類型映射
- [ ] 創建 `lua_event.dart` - 事件定義
- [ ] 創建 `lua_exception.dart` - 錯誤處理

#### LuaEngineDart 實現
- [ ] 實現 `init()` - 初始化 LuaDardo
- [ ] 實現 `dispose()` - 資源釋放
- [ ] 實現 `eval()` - 執行代碼
- [ ] 實現 `call()` - 調用函數
- [ ] 實現 `registerFunction()` - 註冊回調
- [ ] 實現 `setGlobal/getGlobal` - 全局變量
- [ ] 實現事件流機制

#### 測試
- [ ] 單元測試：基礎 Lua 執行
- [ ] 單元測試：雙向調用
- [ ] 單元測試：錯誤處理

---

### Phase 2: Riverpod 整合 (Week 3)

#### Provider 設計
- [ ] 創建 `lua_engine_provider.dart`
- [ ] 創建 `lua_events_provider.dart`
- [ ] 創建狀態映射 Provider

#### 註冊函數實現
- [ ] `setState(key, value)` - 更新狀態
- [ ] `getState(key)` - 讀取狀態
- [ ] `showToast(message)` - Toast 顯示
- [ ] `navigateTo(route)` - 頁面導航
- [ ] `log(level, message)` - 日誌記錄

#### UI 整合
- [ ] 創建 Demo 頁面
- [ ] 實現 Lua 控制 UI 顯示/隱藏
- [ ] 實現 Lua 處理按鈕點擊
- [ ] 實現 Lua 表單驗證

#### 測試
- [ ] 整合測試：Provider 生命週期
- [ ] 整合測試：狀態同步
- [ ] Widget 測試：UI 響應

---

### Phase 3: 熱更新機制 (Week 4)

#### ScriptRepository
- [ ] 實現腳本本地存儲
- [ ] 實現腳本版本管理
- [ ] 實現腳本遠程下載

#### ScriptManager
- [ ] 實現版本檢查
- [ ] 實現簽名驗證
- [ ] 實現 A/B 切換
- [ ] 實現回滾機制

#### 安全措施
- [ ] 移除敏感 Lua 庫 (os, io, debug)
- [ ] 實現執行時間限制
- [ ] 實現指令數限制

#### 測試
- [ ] 測試腳本更新流程
- [ ] 測試回滾機制
- [ ] 測試簽名驗證

---

### Phase 4: 優化與測試 (Week 5)

#### 性能測試
- [ ] Interop Overhead 測試 (目標 <100ms/1000次)
- [ ] Memory Footprint 測試 (目標 <50MB)
- [ ] Startup Time 測試 (目標 <500ms)
- [ ] UI 響應延遲測試 (目標 <16ms)

#### 平台測試
- [ ] Android 測試 (含低端設備)
- [ ] iOS 測試
- [ ] Web 測試

#### 文檔
- [ ] API 文檔
- [ ] 使用指南
- [ ] 範例代碼

---

## 技術決策記錄

### 選擇純 Dart 方案的理由

1. **跨平台一致性**：LuaDardo 在所有平台行為一致
2. **維護成本低**：無需處理 C 編譯、FFI 綁定
3. **Web 支持**：直接編譯為 JS，無需 WASM
4. **調試友好**：可在 Dart 層設置斷點
5. **足夠性能**：UI 邏輯不需要極致性能

### 如果需要升級到混合方案

觸發條件：
- Lua 腳本包含大量數學計算
- 需要每幀執行的邏輯
- 純 Dart 性能無法滿足需求

升級路徑：
1. 保持 LuaEngine 抽象介面不變
2. 新增 LuaEngineNative 實現 (FFI)
3. 新增 LuaEngineWasm 實現 (Web)
4. 在工廠方法中根據平台選擇

---

## 風險與緩解

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| LuaDardo 維護停滯 | 中 | 準備 Fork，或切換到混合方案 |
| App Store 審核拒絕 | 高 | 避免功能級熱更新，僅做配置/修復 |
| 性能不達標 | 中 | 預留升級到 FFI 的路徑 |
| 腳本注入攻擊 | 高 | 簽名驗證 + 沙箱限制 |

---

## 里程碑

| 里程碑 | 日期 | 交付物 |
|--------|------|--------|
| M1: POC 完成 | Week 2 | 基礎 Lua 執行 + 雙向調用 |
| M2: MVP 完成 | Week 3 | Riverpod 整合 + Demo UI |
| M3: 熱更新 | Week 4 | 腳本管理 + 安全機制 |
| M4: 發布準備 | Week 5 | 測試完成 + 文檔 |
