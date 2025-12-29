/// Practical Lua script examples for real-world mobile app use cases
class LuaUseCaseScripts {
  /// 1. 動態表單驗證 - E-commerce checkout form validation
  static const formValidation = '''
-- 表單驗證規則引擎
-- 可從伺服器熱更新驗證規則

local rules = {
  email = {
    required = true,
    pattern = "^[%w.]+@[%w.]+%.%w+\$",
    message = "請輸入有效的電子郵件"
  },
  phone = {
    required = true,
    minLength = 10,
    maxLength = 15,
    pattern = "^[0-9]+\$",
    message = "請輸入有效的電話號碼"
  },
  amount = {
    required = true,
    min = 1,
    max = 100000,
    message = "金額必須在 1-100000 之間"
  }
}

function validateField(fieldName, value)
  local rule = rules[fieldName]
  if not rule then
    return true, nil
  end

  -- 檢查必填
  if rule.required and (value == nil or value == "") then
    return false, fieldName .. " 為必填欄位"
  end

  -- 檢查長度
  if rule.minLength and #tostring(value) < rule.minLength then
    return false, rule.message
  end
  if rule.maxLength and #tostring(value) > rule.maxLength then
    return false, rule.message
  end

  -- 檢查數值範圍
  local numValue = tonumber(value)
  if numValue then
    if rule.min and numValue < rule.min then
      return false, rule.message
    end
    if rule.max and numValue > rule.max then
      return false, rule.message
    end
  end

  return true, nil
end

-- 測試驗證
local testData = {
  email = "test@example.com",
  phone = "0912345678",
  amount = 500
}

local allValid = true
local errors = {}

for field, value in pairs(testData) do
  local valid, err = validateField(field, value)
  if not valid then
    allValid = false
    errors[field] = err
  end
end

callNative('setState', 'formValidation', {
  valid = allValid,
  errors = errors,
  data = testData
})

if allValid then
  print("✅ 表單驗證通過")
  emit('toast', {message = '表單驗證通過！', type = 'success'})
else
  print("❌ 表單驗證失敗")
  for field, err in pairs(errors) do
    print("  - " .. field .. ": " .. err)
  end
end

return allValid
''';

  /// 2. UI 組件可見性控制 - Dynamic UI based on user/config
  static const uiVisibility = '''
-- UI 可見性控制引擎
-- 根據用戶屬性和配置動態控制 UI 顯示

local user = {
  id = "user_123",
  level = "vip",
  age = 28,
  country = "TW",
  registeredDays = 365,
  totalPurchase = 15000
}

local config = {
  showVipBanner = true,
  showNewUserGuide = false,
  enableDarkMode = true,
  promotionEnabled = true
}

-- UI 可見性規則
local uiRules = {
  vipBadge = function()
    return user.level == "vip" or user.level == "svip"
  end,

  newUserGuide = function()
    return user.registeredDays < 7 and config.showNewUserGuide
  end,

  promotionBanner = function()
    return config.promotionEnabled and user.totalPurchase > 1000
  end,

  adultContent = function()
    return user.age >= 18
  end,

  specialOffer = function()
    -- VIP 用戶或消費超過 10000 顯示特殊優惠
    return user.level == "vip" or user.totalPurchase > 10000
  end,

  countrySpecificFeature = function()
    local allowedCountries = {TW = true, HK = true, JP = true}
    return allowedCountries[user.country] == true
  end
}

-- 計算所有 UI 狀態
local uiState = {}
for component, rule in pairs(uiRules) do
  uiState[component] = rule()
  print(component .. ": " .. tostring(uiState[component]))
end

callNative('setState', 'uiVisibility', uiState)
callNative('setState', 'userProfile', user)

emit('toast', {message = 'UI 狀態已更新', type = 'info'})

return uiState
''';

  /// 3. 電商定價與折扣規則
  static const pricingRules = '''
-- 電商定價引擎
-- 支援多種折扣規則的熱更新

local cart = {
  items = {
    {id = "prod_1", name = "iPhone 15", price = 35900, qty = 1, category = "electronics"},
    {id = "prod_2", name = "AirPods Pro", price = 7990, qty = 2, category = "electronics"},
    {id = "prod_3", name = "保護殼", price = 590, qty = 1, category = "accessories"}
  },
  couponCode = "VIP20",
  userId = "user_123",
  userLevel = "vip"
}

-- 折扣規則配置
local discountRules = {
  -- VIP 會員折扣
  vipDiscount = {
    type = "percentage",
    value = 5,
    condition = function(c) return c.userLevel == "vip" end
  },

  -- 電子產品滿 30000 折 3000
  electronicsPromo = {
    type = "fixed",
    value = 3000,
    condition = function(c)
      local total = 0
      for _, item in ipairs(c.items) do
        if item.category == "electronics" then
          total = total + item.price * item.qty
        end
      end
      return total >= 30000
    end
  },

  -- 優惠券折扣
  couponVIP20 = {
    type = "percentage",
    value = 20,
    condition = function(c) return c.couponCode == "VIP20" end,
    maxDiscount = 5000
  }
}

-- 計算購物車總價
function calculateTotal(c)
  local subtotal = 0
  for _, item in ipairs(c.items) do
    subtotal = subtotal + item.price * item.qty
  end
  return subtotal
end

-- 應用折扣規則
function applyDiscounts(c)
  local subtotal = calculateTotal(c)
  local totalDiscount = 0
  local appliedRules = {}

  for name, rule in pairs(discountRules) do
    if rule.condition(c) then
      local discount = 0
      if rule.type == "percentage" then
        discount = subtotal * rule.value / 100
        if rule.maxDiscount and discount > rule.maxDiscount then
          discount = rule.maxDiscount
        end
      else
        discount = rule.value
      end

      totalDiscount = totalDiscount + discount
      table.insert(appliedRules, {
        name = name,
        discount = discount,
        type = rule.type,
        value = rule.value
      })
    end
  end

  return {
    subtotal = subtotal,
    discount = totalDiscount,
    finalPrice = subtotal - totalDiscount,
    appliedRules = appliedRules
  }
end

local result = applyDiscounts(cart)

print("🛒 購物車計算結果:")
print("  小計: NT\$" .. result.subtotal)
print("  折扣: -NT\$" .. result.discount)
print("  應付: NT\$" .. result.finalPrice)
print("  套用規則:")
for _, rule in ipairs(result.appliedRules) do
  print("    - " .. rule.name .. ": -NT\$" .. rule.discount)
end

callNative('setState', 'pricingResult', result)
callNative('setState', 'cartItems', cart.items)

emit('toast', {
  message = '結帳金額: NT\$' .. result.finalPrice,
  type = 'success'
})

return result.finalPrice
''';

  /// 4. A/B 測試與功能開關
  static const abTesting = '''
-- A/B 測試與功能開關引擎
-- 支援遠程配置和即時更新

local userId = "user_" .. math.random(1000, 9999)
local deviceType = "mobile"

-- 功能開關配置（可從遠程獲取）
local featureFlags = {
  newCheckoutFlow = {
    enabled = true,
    rolloutPercentage = 50
  },
  darkModeV2 = {
    enabled = true,
    rolloutPercentage = 100
  },
  aiRecommendation = {
    enabled = true,
    rolloutPercentage = 30,
    allowedDevices = {"mobile", "tablet"}
  },
  videoPlayer = {
    enabled = false,
    rolloutPercentage = 0
  }
}

-- A/B 測試配置
local experiments = {
  buttonColorTest = {
    id = "exp_001",
    variants = {"blue", "green", "red"},
    weights = {50, 30, 20}
  },
  pricingDisplayTest = {
    id = "exp_002",
    variants = {"original", "strikethrough", "percentage"},
    weights = {33, 33, 34}
  },
  onboardingFlowTest = {
    id = "exp_003",
    variants = {"classic", "simplified", "gamified"},
    weights = {40, 40, 20}
  }
}

-- 根據用戶 ID 生成穩定的隨機數 (0-99)
function getUserBucket(uid, salt)
  local hash = 0
  local str = uid .. (salt or "")
  for i = 1, #str do
    hash = (hash * 31 + string.byte(str, i)) % 10000
  end
  return hash % 100
end

-- 檢查功能是否對用戶啟用
function isFeatureEnabled(featureName)
  local feature = featureFlags[featureName]
  if not feature or not feature.enabled then
    return false
  end

  -- 檢查設備類型限制
  if feature.allowedDevices then
    local allowed = false
    for _, device in ipairs(feature.allowedDevices) do
      if device == deviceType then
        allowed = true
        break
      end
    end
    if not allowed then return false end
  end

  -- 檢查灰度發布百分比
  local bucket = getUserBucket(userId, featureName)
  return bucket < feature.rolloutPercentage
end

-- 獲取 A/B 測試變體
function getExperimentVariant(expName)
  local exp = experiments[expName]
  if not exp then return nil end

  local bucket = getUserBucket(userId, exp.id)
  local cumulative = 0

  for i, weight in ipairs(exp.weights) do
    cumulative = cumulative + weight
    if bucket < cumulative then
      return exp.variants[i]
    end
  end

  return exp.variants[1]
end

-- 計算所有功能狀態
local enabledFeatures = {}
for name, _ in pairs(featureFlags) do
  enabledFeatures[name] = isFeatureEnabled(name)
end

-- 計算所有實驗變體
local experimentAssignments = {}
for name, _ in pairs(experiments) do
  experimentAssignments[name] = getExperimentVariant(name)
end

print("👤 用戶 ID: " .. userId)
print("📱 設備類型: " .. deviceType)
print("")
print("🚀 功能開關狀態:")
for name, enabled in pairs(enabledFeatures) do
  local status = enabled and "✅ 啟用" or "❌ 停用"
  print("  " .. name .. ": " .. status)
end

print("")
print("🧪 A/B 測試分組:")
for name, variant in pairs(experimentAssignments) do
  print("  " .. name .. ": " .. variant)
end

callNative('setState', 'abTestUserId', userId)
callNative('setState', 'featureFlags', enabledFeatures)
callNative('setState', 'experiments', experimentAssignments)

emit('toast', {message = 'A/B 測試配置已載入', type = 'info'})

return {features = enabledFeatures, experiments = experimentAssignments}
''';

  /// 5. 工作流/審批引擎
  static const workflowEngine = '''
-- 工作流審批引擎
-- 可用於請假、報銷、訂單審批等場景

-- 請假申請資料
local leaveRequest = {
  id = "req_" .. math.random(10000, 99999),
  type = "annual", -- annual, sick, personal
  employeeId = "emp_001",
  employeeName = "王小明",
  department = "engineering",
  days = 3,
  reason = "家庭旅遊",
  startDate = "2025-01-15",
  status = "pending"
}

-- 員工資訊
local employee = {
  id = "emp_001",
  name = "王小明",
  level = "senior",
  department = "engineering",
  managerId = "mgr_001",
  annualLeaveBalance = 10,
  sickLeaveBalance = 5
}

-- 審批規則配置
local approvalRules = {
  -- 病假規則
  sick = {
    maxDaysAutoApprove = 1,
    requireManagerApproval = function(req) return req.days > 1 end,
    requireHRApproval = function(req) return req.days > 3 end,
    requireDocument = function(req) return req.days > 2 end
  },

  -- 年假規則
  annual = {
    maxDaysAutoApprove = 0,
    requireManagerApproval = function(req) return true end,
    requireHRApproval = function(req) return req.days > 5 end,
    checkBalance = function(req, emp)
      return emp.annualLeaveBalance >= req.days
    end
  },

  -- 事假規則
  personal = {
    maxDaysAutoApprove = 0,
    requireManagerApproval = function(req) return true end,
    requireHRApproval = function(req) return true end,
    requireDirectorApproval = function(req) return req.days > 1 end
  }
}

-- 生成審批流程
function generateWorkflow(request, emp)
  local rules = approvalRules[request.type]
  if not rules then
    return nil, "未知的請假類型"
  end

  local workflow = {
    requestId = request.id,
    steps = {},
    currentStep = 1,
    status = "pending"
  }

  -- 檢查餘額
  if rules.checkBalance and not rules.checkBalance(request, emp) then
    return nil, "假期餘額不足"
  end

  -- 自動審批檢查
  if request.days <= rules.maxDaysAutoApprove then
    table.insert(workflow.steps, {
      type = "auto",
      approver = "system",
      status = "approved",
      comment = "自動審批通過"
    })
    workflow.status = "approved"
    return workflow, nil
  end

  -- 主管審批
  if rules.requireManagerApproval and rules.requireManagerApproval(request) then
    table.insert(workflow.steps, {
      type = "manager",
      approver = emp.managerId,
      status = "pending"
    })
  end

  -- HR 審批
  if rules.requireHRApproval and rules.requireHRApproval(request) then
    table.insert(workflow.steps, {
      type = "hr",
      approver = "hr_dept",
      status = "pending"
    })
  end

  -- 總監審批
  if rules.requireDirectorApproval and rules.requireDirectorApproval(request) then
    table.insert(workflow.steps, {
      type = "director",
      approver = "director",
      status = "pending"
    })
  end

  return workflow, nil
end

local workflow, err = generateWorkflow(leaveRequest, employee)

if err then
  print("❌ 無法建立審批流程: " .. err)
  callNative('setState', 'workflowError', err)
  emit('toast', {message = err, type = 'error'})
else
  print("📋 請假審批流程:")
  print("  申請人: " .. leaveRequest.employeeName)
  print("  類型: " .. leaveRequest.type)
  print("  天數: " .. leaveRequest.days)
  print("  狀態: " .. workflow.status)
  print("")
  print("  審批步驟:")
  for i, step in ipairs(workflow.steps) do
    local status = step.status == "approved" and "✅" or "⏳"
    print("    " .. i .. ". " .. step.type .. " (" .. step.approver .. ") " .. status)
  end

  callNative('setState', 'leaveRequest', leaveRequest)
  callNative('setState', 'approvalWorkflow', workflow)
  callNative('setState', 'employeeInfo', employee)

  emit('toast', {
    message = '已建立 ' .. #workflow.steps .. ' 步審批流程',
    type = 'success'
  })
end

return workflow
''';

  /// 6. 推送通知策略
  static const pushStrategy = '''
-- 推送通知策略引擎
-- 根據用戶行為和偏好決定推送內容

local user = {
  id = "user_456",
  name = "李小華",
  timezone = 8, -- GMT+8
  lastActiveTime = 1735400000 - 3600 * 2, -- 模擬2小時前（使用固定時間戳）
  preferences = {
    marketing = true,
    orderUpdates = true,
    socialNotifications = false,
    quietHoursStart = 22, -- 晚上10點
    quietHoursEnd = 8     -- 早上8點
  },
  segments = {"high_value", "frequent_buyer", "mobile_user"},
  recentPurchases = 3,
  cartItems = 2,
  wishlistItems = 5
}

local currentHour = 14 -- 下午2點 (測試用)

-- 推送模板
local pushTemplates = {
  cartReminder = {
    title = "您的購物車還有商品",
    body = "別讓心儀商品溜走，立即結帳享優惠！",
    priority = "high",
    category = "marketing"
  },
  priceDropAlert = {
    title = "💰 降價通知",
    body = "您關注的商品降價了！",
    priority = "high",
    category = "marketing"
  },
  orderShipped = {
    title = "📦 訂單已出貨",
    body = "您的訂單正在配送中",
    priority = "normal",
    category = "orderUpdates"
  },
  inactiveReminder = {
    title = "好久不見！",
    body = "回來看看有什麼新商品",
    priority = "low",
    category = "marketing"
  }
}

-- 檢查是否在靜音時段
function isQuietHours(hour, prefs)
  local start = prefs.quietHoursStart
  local endH = prefs.quietHoursEnd

  if start > endH then
    -- 跨午夜 (例如 22-8)
    return hour >= start or hour < endH
  else
    return hour >= start and hour < endH
  end
end

-- 選擇最佳推送內容
function selectPushContent(u)
  local candidates = {}

  -- 購物車提醒
  if u.cartItems > 0 then
    table.insert(candidates, {
      template = "cartReminder",
      score = 80 + u.cartItems * 5,
      reason = "購物車有 " .. u.cartItems .. " 件商品"
    })
  end

  -- 願望清單降價
  if u.wishlistItems > 0 then
    table.insert(candidates, {
      template = "priceDropAlert",
      score = 70,
      reason = "關注商品可能降價"
    })
  end

  -- 久未活躍提醒（使用固定時間戳模擬）
  local currentTime = 1735400000
  local inactiveHours = (currentTime - u.lastActiveTime) / 3600
  if inactiveHours > 24 then
    table.insert(candidates, {
      template = "inactiveReminder",
      score = 50,
      reason = "超過 " .. math.floor(inactiveHours) .. " 小時未活躍"
    })
  end

  -- 按分數排序
  table.sort(candidates, function(a, b) return a.score > b.score end)

  return candidates
end

-- 執行推送決策
function decidePush(u, hour)
  local result = {
    shouldPush = false,
    reason = "",
    content = nil,
    scheduledTime = nil
  }

  -- 檢查靜音時段
  if isQuietHours(hour, u.preferences) then
    result.reason = "目前為靜音時段"
    result.scheduledTime = u.preferences.quietHoursEnd
    return result
  end

  -- 選擇推送內容
  local candidates = selectPushContent(u)
  if #candidates == 0 then
    result.reason = "無適合的推送內容"
    return result
  end

  local selected = candidates[1]
  local template = pushTemplates[selected.template]

  -- 檢查用戶偏好
  if not u.preferences[template.category] then
    result.reason = "用戶已關閉 " .. template.category .. " 類別通知"
    return result
  end

  result.shouldPush = true
  result.reason = selected.reason
  result.content = {
    template = selected.template,
    title = template.title,
    body = template.body,
    priority = template.priority,
    score = selected.score
  }

  return result
end

local decision = decidePush(user, currentHour)

print("🔔 推送決策結果:")
print("  用戶: " .. user.name)
print("  目前時間: " .. currentHour .. ":00")
print("")

if decision.shouldPush then
  print("  ✅ 決定推送")
  print("  原因: " .. decision.reason)
  print("  標題: " .. decision.content.title)
  print("  內容: " .. decision.content.body)
  print("  優先級: " .. decision.content.priority)
  print("  評分: " .. decision.content.score)

  emit('toast', {message = '模擬推送: ' .. decision.content.title, type = 'info'})
else
  print("  ❌ 不推送")
  print("  原因: " .. decision.reason)
  if decision.scheduledTime then
    print("  建議時間: " .. decision.scheduledTime .. ":00")
  end
end

callNative('setState', 'pushDecision', decision)
callNative('setState', 'pushUser', user)

return decision
''';

  /// 所有用例列表
  static const List<Map<String, String>> allUseCases = [
    {
      'id': 'formValidation',
      'name': '表單驗證',
      'icon': '📝',
      'description': '動態表單驗證規則引擎',
    },
    {
      'id': 'uiVisibility',
      'name': 'UI 控制',
      'icon': '🎨',
      'description': '根據用戶/配置控制 UI 顯示',
    },
    {
      'id': 'pricingRules',
      'name': '定價引擎',
      'icon': '💰',
      'description': '電商折扣與定價規則',
    },
    {
      'id': 'abTesting',
      'name': 'A/B 測試',
      'icon': '🧪',
      'description': '功能開關與實驗分組',
    },
    {
      'id': 'workflowEngine',
      'name': '審批流程',
      'icon': '📋',
      'description': '工作流引擎與審批邏輯',
    },
    {
      'id': 'pushStrategy',
      'name': '推送策略',
      'icon': '🔔',
      'description': '智能推送通知決策',
    },
  ];

  static String getScript(String id) {
    switch (id) {
      case 'formValidation':
        return formValidation;
      case 'uiVisibility':
        return uiVisibility;
      case 'pricingRules':
        return pricingRules;
      case 'abTesting':
        return abTesting;
      case 'workflowEngine':
        return workflowEngine;
      case 'pushStrategy':
        return pushStrategy;
      default:
        return '-- Unknown use case';
    }
  }
}
