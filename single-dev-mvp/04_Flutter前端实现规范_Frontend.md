# EmoBot Flutter 前端实现规范

## 1. 技术选型

- Flutter Stable
- `go_router`
- `flutter_riverpod`
- `dio`
- `flutter_secure_storage`
- `shared_preferences`
- `sentry_flutter`

这版前端目标不是极简工具，而是 **“场景首页 + 四模块入口 + 三模式微互动”**。

---

## 2. 推荐目录结构

```text
lib/
├─ app/
│  ├─ app.dart
│  ├─ router.dart
│  └─ theme/
├─ core/
│  ├─ constants/
│  ├─ network/
│  ├─ storage/
│  ├─ models/
│  └─ widgets/
├─ features/
│  ├─ splash/
│  ├─ home/
│  ├─ mood_weather/
│  ├─ treehole/
│  ├─ modes/
│  │  ├─ joy_mode/
│  │  ├─ low_mode/
│  │  └─ anger_mode/
│  ├─ blind_box/
│  ├─ growth/
│  ├─ records/
│  ├─ settings/
│  └─ safety/
├─ services/
│  ├─ analytics_service.dart
│  ├─ chat_stream_service.dart
│  ├─ mode_session_service.dart
│  └─ device_identity_service.dart
└─ main.dart
```

---

## 3. 路由表

| 路由 | 页面 |
|---|---|
| `/` | SplashPage |
| `/home` | MainTabShell |
| `/treehole` | TreeholePage |
| `/mood-weather` | MoodWeatherPage |
| `/mode/joy` | JoyModePage |
| `/mode/low` | LowModePage |
| `/mode/anger` | AngerModePage |
| `/blind-box` | BlindBoxPage |
| `/growth` | MomoGrowthPage |
| `/records` | RecordsPage |
| `/settings` | SettingsPage |
| `/privacy` | PrivacyPage |
| `/report` | ReportPage |
| `/safety` | SafetyBlockPage |

### 3.1 Tab 结构
- Tab 1：首页
- Tab 2：今日情绪 / 记录
- Tab 3：我的

---

## 4. 页面组件树

### 4.1 HomePage
```text
Scaffold
├─ SafeArea
│  ├─ HomeHeader
│  ├─ MomoIslandHero
│  ├─ LastSummaryCard
│  ├─ ModuleEntryGrid
│  └─ QuickMoodButton
└─ MainBottomTabBar
```

### 4.2 MoodWeatherPage
```text
Scaffold
├─ AppBar
├─ EmotionSelector
├─ IntensitySlider
├─ NoteInput
├─ SubmitButton
├─ EmpathyCard
└─ InviteCardRow
```

### 4.3 TreeholePage
```text
Scaffold
├─ TreeholeHeader
├─ Expanded(MessageList)
├─ OptionalSuggestionCard
└─ ChatInputBar
```

### 4.4 JoyModePage
```text
Scaffold
├─ ModeHeader
├─ Expanded(LightParticleScene)
├─ HintText
└─ FinishButton
```

### 4.5 LowModePage
```text
Scaffold
├─ ModeHeader
├─ Expanded(BreathingCloudScene)
├─ GuidanceText
└─ FinishButton
```

### 4.6 AngerModePage
```text
Scaffold
├─ ModeHeader
├─ Expanded(BubbleReleaseScene)
├─ GuidanceText
└─ FinishButton
```

### 4.7 BlindBoxPage
```text
Scaffold
├─ BlindBoxHeader
├─ OptionalWorryInput
├─ DrawBoxButton
├─ ResultCard
└─ SaveCardButton
```

### 4.8 MomoGrowthPage
```text
Scaffold
├─ GrowthHeader
├─ MomoStageCard
├─ ProgressBarCard
└─ RecentGrowthEvents
```

---

## 5. 状态管理

### 5.1 Provider 划分
- `deviceIdentityProvider`
- `homeSummaryProvider`
- `moodWeatherDraftProvider`
- `treeholeSessionProvider`
- `chatStreamProvider`
- `modeSessionProvider`
- `blindBoxProvider`
- `growthProvider`
- `recordsProvider`
- `settingsProvider`
- `safetyStateProvider`

### 5.2 原则
- feature 内状态局部管理
- 跨页面状态走 provider
- 三种模式共享一套 mode session state

---

## 6. 数据流

### 6.1 情绪气象台
1. 用户选择情绪和强度
2. 提交 `/checkins`
3. 页面收到共情短文 + 推荐模块
4. 用户选择聊天 / 模式 / 盲盒

### 6.2 树洞
1. 创建会话
2. 发送消息
3. 接收 SSE 增量
4. 完成后提交 helpful_score

### 6.3 模式互动
1. 打开 `/mode/:type`
2. 本地执行动画交互
3. 完成时提交 `/mode-sessions`
4. 刷新 growth 和 records

### 6.4 盲盒
1. 输入烦恼一句话，可空
2. 请求 `/blind-box/draw`
3. 获取 result card
4. 可收藏

### 6.5 成长
1. 首页和我的页拉 `/growth/summary`
2. 显示当前阶段和成长值
3. 使用后自动刷新

---

## 7. 本地存储策略

### 7.1 必存
- 匿名 device token
- 最近一次首页摘要
- 用户设置

### 7.2 可缓存
- 最近 7 天记录
- growth summary
- 盲盒最近结果

### 7.3 不长期缓存
- 高危完整文本
- 长历史对话原文

---

## 8. 主题和 Token 映射

### 8.1 Theme 模块
- `AppColors`
- `AppTextStyles`
- `AppSpacing`
- `AppRadii`
- `AppShadows`

### 8.2 公共组件
- `EbPrimaryButton`
- `EbSecondaryButton`
- `EbGlassCard`
- `EbMoodChip`
- `EbChatBubble`
- `EbEntryCard`
- `EbStageBadge`

---

## 9. SSE 对话流实现建议

事件：
- `message_start`
- `message_delta`
- `message_done`
- `safety_block`
- `error`

策略：
- `message_start` 创建 assistant bubble
- `message_delta` 逐步追加
- `message_done` 才显示建议卡和结束反馈
- `safety_block` 立即跳 `/safety`

---

## 10. 三模式实现建议

### 10.1 通用模式框架
抽象 `ModeScaffold`：
- Header
- SceneLayer
- HintText
- FinishButton

### 10.2 JoyMode
- 点击 / 滑动收集光粒
- 记录 touch count
- 结束时生成温暖反馈

### 10.3 LowMode
- 用 `AnimationController` 做呼吸环
- 3 轮计数

### 10.4 AngerMode
- 点击气泡淡出
- 收尾阶段切到 Calm 状态

---

## 11. 动画实现建议

优先使用：
- `AnimationController`
- `TweenAnimationBuilder`
- `AnimatedContainer`
- `AnimatedOpacity`

不要引入：
- 自定义粒子引擎
- 复杂 shader
- 3D 场景

---

## 12. 错误处理

- MoodWeather 提交失败：停留当前页，提示重试
- 树洞超时：展示柔和 fallback 文案
- 盲盒失败：允许重新抽取
- 模式失败：仍可手动结束并返回
- 高危熔断：独立页，不与普通错误共用

---

## 13. 性能边界

- 首页不超过 2 层动态背景
- 三模式都保证单场景单主动画
- 列表页统一 `ListView.builder`
- 对话页长会话只保留必要渲染

---

## 14. 页面实现 Checklist

### Home
- [ ] 四模块入口可见
- [ ] `momo` 主视觉完成
- [ ] 最近摘要可见

### MoodWeather
- [ ] 情绪类型、强度、描述可提交
- [ ] 共情卡和邀请卡出现

### Treehole
- [ ] SSE 可用
- [ ] 高危跳转可用

### Three Modes
- [ ] 三页面都能走通
- [ ] 三者视觉明显不同

### Blind Box
- [ ] 可抽卡
- [ ] 可收藏

### Growth
- [ ] 可显示阶段和成长值

### Records / Settings
- [ ] 可查看记录
- [ ] 删除 / 举报 / 隐私可用
