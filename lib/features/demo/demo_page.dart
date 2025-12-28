import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lua_engine/lua_engine.dart';
import '../../core/providers/lua_providers.dart';

/// Demo 頁面 - 展示 Lua 引擎的各種功能
class DemoPage extends ConsumerStatefulWidget {
  const DemoPage({super.key});

  @override
  ConsumerState<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends ConsumerState<DemoPage> {
  final TextEditingController _codeController = TextEditingController();
  final List<String> _logs = [];
  String _result = '';
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    // 設置默認 Lua 代碼示例
    _codeController.text = '''
-- 簡單計算
local result = 10 + 20
print("計算結果: " .. result)

-- 使用 setState 更新 Flutter 狀態
callNative('setState', 'counter', result)

-- 返回結果
return result
''';

    // 初始化 Lua 引擎
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEngine();
    });
  }

  Future<void> _initEngine() async {
    await ref.read(luaEngineProvider.notifier).initialize();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 執行 Lua 代碼
  Future<void> _executeCode() async {
    if (_isExecuting) return;

    setState(() {
      _isExecuting = true;
      _result = '';
    });

    try {
      final result = await ref
          .read(luaEngineProvider.notifier)
          .eval(_codeController.text, chunkName: 'demo');

      setState(() {
        _result = '返回值: $result';
      });
    } catch (e) {
      setState(() {
        _result = '錯誤: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  /// 執行預設示例
  Future<void> _runExample(String name) async {
    String code;

    switch (name) {
      case 'hello':
        code = 'print("Hello from Lua!")';
        break;

      case 'counter':
        code = '''
-- 獲取當前計數器值
local current = callNative('getState', 'counter') or 0
print("當前計數: " .. tostring(current))

-- 遞增
local newValue = current + 1
callNative('setState', 'counter', newValue)
print("新計數: " .. newValue)

return newValue
''';
        break;

      case 'toast':
        code = '''
-- 顯示 Toast
callNative('showToast', '這是來自 Lua 的 Toast!', 'success')
return "Toast sent"
''';
        break;

      case 'table':
        code = '''
-- Lua Table 示例
local user = {
  name = "Alice",
  age = 25,
  skills = {"Flutter", "Lua", "Dart"}
}

print("用戶名: " .. user.name)
print("年齡: " .. user.age)

-- 更新狀態
callNative('setState', 'user', user)

return user
''';
        break;

      case 'loop':
        code = '''
-- 循環示例
local sum = 0
for i = 1, 10 do
  sum = sum + i
  print("累加: " .. i .. " -> " .. sum)
end

callNative('setState', 'sum', sum)
return sum
''';
        break;

      case 'function':
        code = '''
-- 定義函數
function factorial(n)
  if n <= 1 then
    return 1
  end
  return n * factorial(n - 1)
end

-- 計算階乘
local result = factorial(5)
print("5! = " .. result)

return result
''';
        break;

      default:
        code = 'print("Unknown example")';
    }

    _codeController.text = code;
    await _executeCode();
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(luaEngineProvider);
    final stateMap = ref.watch(luaStateMapProvider);

    // 監聽事件
    ref.listen(luaEventsProvider, (previous, next) {
      next.whenData((event) {
        setState(() {
          _logs.add('[${event.type.name}] ${event.data}');
          if (_logs.length > 50) {
            _logs.removeAt(0);
          }
        });

        // 處理 Toast 事件
        if (event.type == LuaEventType.toast) {
          _showToast(event.data['message'] ?? '', event.data['type'] ?? 'info');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Lua Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(luaEngineProvider.notifier).reset();
              ref.read(luaStateMapProvider.notifier).clear();
              setState(() {
                _logs.clear();
                _result = '';
              });
            },
            tooltip: '重置引擎',
          ),
        ],
      ),
      body: Column(
        children: [
          // 狀態欄
          _buildStatusBar(engineState),

          // 示例按鈕
          _buildExampleButtons(),

          // 代碼編輯器
          Expanded(
            flex: 3,
            child: _buildCodeEditor(),
          ),

          // 結果區域
          Expanded(
            flex: 2,
            child: _buildResultArea(stateMap),
          ),
        ],
      ),
    );
  }

  /// 狀態欄
  Widget _buildStatusBar(LuaEngineProviderState engineState) {
    Color statusColor;
    String statusText;

    if (engineState.error != null) {
      statusColor = Colors.red;
      statusText = '錯誤: ${engineState.error}';
    } else if (engineState.isInitializing) {
      statusColor = Colors.orange;
      statusText = '初始化中...';
    } else if (engineState.isReady) {
      statusColor = Colors.green;
      statusText = '就緒';
    } else {
      statusColor = Colors.grey;
      statusText = '未初始化';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: statusColor),
          const SizedBox(width: 8),
          Text(
            'Lua 引擎: $statusText',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (engineState.isReady)
            Text(
              'LuaDardo v0.0.5',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// 示例按鈕
  Widget _buildExampleButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _exampleButton('Hello', 'hello', Icons.waving_hand),
          _exampleButton('計數器', 'counter', Icons.add_circle),
          _exampleButton('Toast', 'toast', Icons.notifications),
          _exampleButton('Table', 'table', Icons.table_chart),
          _exampleButton('循環', 'loop', Icons.loop),
          _exampleButton('函數', 'function', Icons.functions),
        ],
      ),
    );
  }

  Widget _exampleButton(String label, String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: _isExecuting ? null : () => _runExample(name),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  /// 代碼編輯器
  Widget _buildCodeEditor() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.code, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Lua 代碼',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isExecuting ? null : _executeCode,
                  icon: _isExecuting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isExecuting ? '執行中...' : '執行'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: '-- 在此輸入 Lua 代碼',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 結果區域
  Widget _buildResultArea(Map<String, dynamic> stateMap) {
    return DefaultTabController(
      length: 3,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '結果'),
                Tab(text: '狀態'),
                Tab(text: '日誌'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 結果 Tab
                  _buildResultTab(),

                  // 狀態 Tab
                  _buildStateTab(stateMap),

                  // 日誌 Tab
                  _buildLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTab() {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.topLeft,
      child: Text(
        _result.isEmpty ? '尚無結果' : _result,
        style: TextStyle(
          fontFamily: 'monospace',
          color: _result.startsWith('錯誤') ? Colors.red : Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildStateTab(Map<String, dynamic> stateMap) {
    if (stateMap.isEmpty) {
      return const Center(
        child: Text('尚無狀態數據', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: stateMap.length,
      itemBuilder: (context, index) {
        final entry = stateMap.entries.elementAt(index);
        return ListTile(
          dense: true,
          leading: const Icon(Icons.data_object, size: 20),
          title: Text(entry.key),
          subtitle: Text(
            '${entry.value}',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        );
      },
    );
  }

  Widget _buildLogTab() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text('尚無日誌', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _logs.length,
      reverse: true,
      itemBuilder: (context, index) {
        final log = _logs[_logs.length - 1 - index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            log,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  void _showToast(String message, String type) {
    Color backgroundColor;
    switch (type) {
      case 'success':
        backgroundColor = Colors.green;
        break;
      case 'error':
        backgroundColor = Colors.red;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        break;
      default:
        backgroundColor = Colors.blue;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
