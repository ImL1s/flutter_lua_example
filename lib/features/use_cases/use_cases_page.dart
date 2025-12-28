import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/lua_providers.dart';
import '../../core/lua_engine/lua_event.dart';
import 'use_case_scripts.dart';

/// 實用場景展示頁面
class UseCasesPage extends ConsumerStatefulWidget {
  const UseCasesPage({super.key});

  @override
  ConsumerState<UseCasesPage> createState() => _UseCasesPageState();
}

class _UseCasesPageState extends ConsumerState<UseCasesPage> {
  String? _selectedUseCase;
  String _currentScript = '';
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    // 自動初始化 Lua 引擎
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEngine();
    });
  }

  Future<void> _initEngine() async {
    final engineState = ref.read(luaEngineProvider);
    if (!engineState.isReady) {
      await ref.read(luaEngineProvider.notifier).initialize();
    }
  }

  Future<void> _executeUseCase(String id) async {
    setState(() {
      _selectedUseCase = id;
      _currentScript = LuaUseCaseScripts.getScript(id);
      _isExecuting = true;
    });

    try {
      // 清除之前的狀態
      ref.read(luaStateMapProvider.notifier).clear();

      await ref.read(luaEngineProvider.notifier).eval(_currentScript);
      setState(() {
        _isExecuting = false;
      });
    } catch (e) {
      setState(() {
        _isExecuting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('執行錯誤: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(luaEngineProvider);
    final stateMap = ref.watch(luaStateMapProvider);

    // 監聽事件
    ref.listen<AsyncValue<LuaEvent>>(luaEventsProvider, (previous, next) {
      next.whenData((event) {
        if (event.type == LuaEventType.toast) {
          final message = event.data['message'] ?? '';
          final type = event.data['type'] ?? 'info';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.toString()),
              backgroundColor: _getToastColor(type.toString()),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('實用場景示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ref.read(luaStateMapProvider.notifier).clear();
              await ref.read(luaEngineProvider.notifier).reset();
              setState(() {
                _selectedUseCase = null;
              });
            },
            tooltip: '重置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 引擎狀態
          _buildEngineStatus(engineState),

          // 用例選擇網格
          _buildUseCaseGrid(),

          // 結果展示區域
          Expanded(
            child: _selectedUseCase == null
                ? _buildWelcomeMessage()
                : _buildResultArea(stateMap),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineStatus(LuaEngineProviderState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: state.isReady
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            state.isReady ? Icons.check_circle : Icons.hourglass_empty,
            size: 16,
            color: state.isReady ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            state.isReady ? 'Lua 引擎就緒' : '引擎初始化中...',
            style: TextStyle(
              color: state.isReady ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCaseGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '選擇場景運行 Lua 腳本：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LuaUseCaseScripts.allUseCases.map((useCase) {
              final isSelected = _selectedUseCase == useCase['id'];
              return _UseCaseButton(
                id: useCase['id']!,
                name: useCase['name']!,
                icon: useCase['icon']!,
                description: useCase['description']!,
                isSelected: isSelected,
                isExecuting: _isExecuting && isSelected,
                onTap: () => _executeUseCase(useCase['id']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '選擇上方場景查看 Lua 腳本實際應用',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '這些場景展示了 Lua 在真實 APP 中的常見用途',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea(Map<String, dynamic> stateMap) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '狀態結果'),
              Tab(text: 'Lua 腳本'),
              Tab(text: '說明'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStateView(stateMap),
                _buildScriptView(),
                _buildExplanationView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateView(Map<String, dynamic> stateMap) {
    if (_isExecuting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stateMap.isEmpty) {
      return const Center(child: Text('尚無狀態數據'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: stateMap.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _getValuePreview(entry.value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _formatValue(entry.value),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScriptView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          _currentScript,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationView() {
    final useCase = LuaUseCaseScripts.allUseCases.firstWhere(
      (uc) => uc['id'] == _selectedUseCase,
      orElse: () => {'name': '', 'description': ''},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useCase['name'] ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useCase['description'] ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildExplanationContent(),
        ],
      ),
    );
  }

  Widget _buildExplanationContent() {
    final explanations = {
      'formValidation': '''
## 動態表單驗證

### 應用場景
- 電商結帳表單
- 用戶註冊表單
- 問卷調查

### 熱更新優勢
- 新增驗證規則無需發版
- 不同地區可配置不同規則
- A/B 測試不同驗證策略

### 關鍵功能
- 必填欄位檢查
- 長度限制
- 正則表達式匹配
- 數值範圍驗證
''',
      'uiVisibility': '''
## UI 可見性控制

### 應用場景
- VIP 專屬功能
- 地區限定功能
- 新用戶引導
- 年齡限制內容

### 熱更新優勢
- 即時調整 UI 佈局
- 快速響應市場變化
- 個性化用戶體驗

### 關鍵功能
- 用戶屬性判斷
- 配置開關
- 多條件組合
''',
      'pricingRules': '''
## 電商定價引擎

### 應用場景
- 促銷活動
- 會員折扣
- 滿減優惠
- 優惠券系統

### 熱更新優勢
- 快速上線促銷活動
- 靈活調整折扣規則
- 多規則疊加計算

### 關鍵功能
- 百分比折扣
- 固定金額減免
- 最大折扣限制
- 多規則優先級
''',
      'abTesting': '''
## A/B 測試引擎

### 應用場景
- 功能灰度發布
- UI 樣式測試
- 算法效果對比
- 新功能實驗

### 熱更新優勢
- 即時調整實驗分組
- 動態開關功能
- 快速迭代驗證

### 關鍵功能
- 穩定的用戶分桶
- 權重分配
- 設備類型過濾
- 灰度發布百分比
''',
      'workflowEngine': '''
## 工作流審批引擎

### 應用場景
- 請假申請
- 報銷審批
- 訂單審核
- 合同簽署

### 熱更新優勢
- 調整審批層級
- 修改審批條件
- 新增審批節點

### 關鍵功能
- 多級審批
- 條件分支
- 自動審批
- 餘額檢查
''',
      'pushStrategy': '''
## 推送通知策略

### 應用場景
- 購物車提醒
- 活動通知
- 個性化推薦
- 召回推送

### 熱更新優勢
- 即時調整推送策略
- 優化推送時機
- 個性化推送內容

### 關鍵功能
- 靜音時段
- 用戶偏好
- 內容評分
- 優先級排序
''',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Text(
        explanations[_selectedUseCase] ?? '選擇場景查看說明',
        style: const TextStyle(height: 1.6),
      ),
    );
  }

  String _getValuePreview(dynamic value) {
    if (value is Map) return 'Object with ${value.length} keys';
    if (value is List) return 'Array with ${value.length} items';
    return value.toString();
  }

  String _formatValue(dynamic value, [int indent = 0]) {
    final prefix = '  ' * indent;
    if (value is Map) {
      if (value.isEmpty) return '{}';
      final entries = value.entries.map((e) {
        return '$prefix  ${e.key}: ${_formatValue(e.value, indent + 1)}';
      }).join('\n');
      return '{\n$entries\n$prefix}';
    }
    if (value is List) {
      if (value.isEmpty) return '[]';
      final items =
          value.map((e) => '$prefix  ${_formatValue(e, indent + 1)}').join('\n');
      return '[\n$items\n$prefix]';
    }
    if (value is String) return '"$value"';
    if (value is bool) return value ? 'true' : 'false';
    return value.toString();
  }

  Color _getToastColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class _UseCaseButton extends StatelessWidget {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isSelected;
  final bool isExecuting;
  final VoidCallback onTap;

  const _UseCaseButton({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.isExecuting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isExecuting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              if (isExecuting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
