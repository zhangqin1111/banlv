# EmoBot — 技术架构文档
> 角色：技术架构师 (Architect) 视角  
> 版本：v1.0 · 2026-04-17

---

## 1. 架构目标与非功能需求 (NFR)

| 维度 | 目标 |
|------|------|
| 可用性 | 99.9%（核心对话 99.95%）|
| 冷启动 | ≤ 2.5s（中端机）|
| AI 响应 P95 | ≤ 2.5s（流式首 token ≤ 0.8s）|
| 闯关游戏 FPS | ≥ 45（中低端机），≥ 60（旗舰）|
| 数据合规 | 《个人信息保护法》《生成式 AI 服务管理办法》 |
| 端侧存储加密 | AES-256-GCM，密钥由 iOS Keychain / Android Keystore 托管 |
| 多端 | iOS / Android（Q1）→ 微信小程序 + Web（Q3）|

## 2. 宏观架构图 (C4 Level 1)

```
┌────────────────────────────────────────────────────────┐
│                      移动端 App                          │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐          │
│  │ 首页 │ │ 树洞 │ │气象台│ │盲盒机│ │专注森林│          │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘          │
│      │         │       │        │        │            │
│  Flutter / RN 通用壳 + Cocos Engine (游戏子视图)         │
└───────────┬──────────────────────┬─────────────────────┘
            │ HTTPS/WSS             │ WebRTC (未来语音)
┌───────────▼────────┐    ┌─────────▼──────────┐
│   API Gateway      │    │ Realtime Gateway   │
│ (APISIX + JWT)     │    │ (Socket.IO / WS)   │
└─────────┬──────────┘    └─────────┬──────────┘
          │                          │
┌─────────▼──────────────────────────▼──────────────┐
│                服务层（微服务集群）                   │
│ User / Mood / Chat / Game / Growth / Crisis / CMS │
└─────────┬──────────────────────────────────────────┘
          │
┌─────────▼────────────────────────────┐
│            AI 编排与能力层              │
│ Prompt Router · 安全过滤 · 流式代理     │
│ ├ LLM Provider Pool（Claude/通义/DS）   │
│ ├ 情绪分类模型（本地+云 BERT）          │
│ └ TTS / ASR                            │
└─────────┬────────────────────────────┘
          │
┌─────────▼────────────┐
│ 数据层                 │
│ Postgres · Redis ·    │
│ MongoDB · ClickHouse  │
│ · OSS · Vector DB     │
└───────────────────────┘
```

## 3. 客户端分层架构

```
┌──── Presentation ─────────────────────┐
│ Widgets / Screens / Animations         │
│ Lottie / Rive / Particle Engine        │
├──── State Management ──────────────────┤
│ Riverpod (Flutter) / Zustand (RN)     │
├──── Domain ────────────────────────────┤
│ UseCase · Emotion Analyzer · Energy   │
├──── Data ──────────────────────────────┤
│ Repository · API Client · Cache (Isar)│
├──── Platform ──────────────────────────┤
│ Native Bridge · Game Engine SDK · ML  │
└────────────────────────────────────────┘
```

**关键子系统**：
- **游戏引擎嵌入**：Cocos Creator 打包为 iOS Framework / Android AAR，作为独立子 View 嵌入 Flutter Platform View，双向通信走 MethodChannel + JSON。
- **端侧 ML**：使用 ONNX Runtime Mobile 运行轻量情绪分类模型（10MB），离线分流闯关模式，云端仅在置信度 <0.75 时兜底调用。
- **本地加密库**：SQLCipher + Isar 保存情绪日记，用户生物识别解锁。

## 4. 后端微服务切分

| 服务 | 边界 | 主存储 | 备注 |
|------|------|--------|------|
| `user-svc` | 登录注册 / 实名 / 生物识别 | Postgres | JWT + Refresh |
| `mood-svc` | 情绪打卡 / 日记 / 趋势 | Postgres + ClickHouse | 写分表 |
| `chat-svc` | 树洞会话 / 上下文 / 流式 | Postgres + Redis Stream | SSE |
| `game-svc` | 关卡配置 / 进度 / 排行（私密）| MongoDB | 游戏节点私有 |
| `growth-svc` | 能量账本 / momo 进化 / 勋章 | Postgres | 事件溯源 |
| `box-svc` | 盲盒生成 / 安慰卡片库 | MongoDB | 运营后台 |
| `content-svc` | 塔罗 / MBTI / 星座 / 冥想音频 | CMS + OSS | 分发 CDN |
| `crisis-svc` | 高危识别 / 热线对接 / 人工审核 | Postgres | 独立审计 |
| `ai-gateway` | 统一 LLM 代理 / 限流 / 多路由 | Redis | SSE 流式 |
| `notify-svc` | 推送 / 短信 / 站内信 | Postgres + RabbitMQ | 量化静默 |
| `admin-cms` | 运营后台 / 审核 / 配置中心 | Postgres | RBAC |

**通信**：gRPC 内部 + REST 对外；事件总线用 Kafka（用户行为）+ RabbitMQ（通知推送）。

## 5. 数据架构

### 5.1 主存储划分
- **Postgres 16**：强一致业务（账户、订阅、能量账本、成就）
- **MongoDB 7**：非结构化（对话上下文、卡片模板、游戏关卡 JSON）
- **ClickHouse**：情绪趋势聚合、热力图、漏斗分析
- **Redis 7**：会话缓存、限流、排行榜（私有）、Session
- **OSS（阿里云/腾讯云）**：音频、Lottie、皮肤资产，配 CDN
- **Qdrant / Milvus（Vector DB）**：AI 对话长期记忆向量检索

### 5.2 关键数据模型
```ts
// 情绪事件（不可变，事件溯源）
interface MoodEvent {
  id: UUID; userId: UUID;
  ts: timestamp;                // UTC
  emotion: 'happy' | 'low' | 'angry' | 'calm' | 'complex';
  intensity: 0..10;
  keywords: string[];           // 端侧 NLP 提取
  encryptedText: string;        // 用户原文（AES-GCM，端侧加密）
  source: 'weather' | 'treehole' | 'box';
}

// 能量账本（幂等，防刷）
interface EnergyLedger {
  id: UUID; userId: UUID;
  delta: int; reason: string;
  requestId: UUID; // 幂等键
  signature: string; // 防篡改
}
```

### 5.3 隐私分层
- **L1 极敏感**（对话原文 / 日记）：端侧加密，云端仅存密文副本 + 索引哈希。
- **L2 结构化**（情绪打分 / 时间）：云端明文，用户可一键删除。
- **L3 聚合**（匿名热力）：脱敏后进 ClickHouse。

## 6. AI 能力架构

```
用户输入
   │
   ▼
[Prompt Router] ── 场景：树洞 / 盲盒 / 日记 / 闯关文案
   │
   ├─ [安全前置过滤] 敏感词 + 自伤/自杀分类器
   │       ↓ 若触发 → 交给 crisis-svc，终止 LLM 调用
   │
   ├─ [情绪分类] 端侧 ONNX（快）→ 云端 BERT（准）
   │
   ├─ [记忆检索] 向量召回 top-5 近似历史对话
   │
   ├─ [Prompt 组装] System + Persona(momo) + Memory + User
   │
   ├─ [LLM 调用] 多 Provider 池
   │     · 默认：国产合规模型（通义/豆包/DeepSeek）
   │     · 备份：MiniMax / 智谱
   │     · 离线：本地 3B 蒸馏模型（可选）
   │
   ├─ [后置过滤] 内容合规 + 情绪安全二次扫
   │
   ▼
 流式 SSE → 客户端
```

**关键策略**：
- **双模型校验**：高危语境下，主模型回复后再让裁判模型打分，不合格触发兜底安抚模板。
- **Prompt 合规**：System Prompt 明确声明"不做诊断，不用抑郁症等临床词"，每季度 Red-Team 测试。
- **延迟控制**：流式首 token < 800ms；Provider 2s 无响应自动切换。

### 6.1 AI 伦理四层防护网（P0 规避落地细节）

对应《产品文档 §12.1》的工程实现：

```
┌── L1 输入层 ──────────────────────────────────────────┐
│ high-risk-dict（2000+ 词库，热更新）                    │
│   ↓ 命中                                                │
│ 绕过 LLM → crisis-svc → 温柔模板 + 热线浮层              │
├── L2 Prompt 层 ────────────────────────────────────────┤
│ SystemPrompt 强约束（禁用临床词 / 强制医嘱免责）          │
│ 每次注入 persona + safety_contract                      │
├── L3 输出层 ────────────────────────────────────────────┤
│ Judge Model（Qwen-1.5B 微调安全分类器）                  │
│ score < 0.7 → 重试 1 次 → 再失败 → 兜底模板              │
│ 0.1% 流量异步入人工审核队列                              │
├── L4 审计层 ────────────────────────────────────────────┤
│ 对话摘要 + 命中理由 → SLS 不可变日志                      │
│ 周维度 Red-Team 回归（20 组高危剧本）                    │
└─────────────────────────────────────────────────────────┘
```

**关键接口约定**：
```yaml
POST /ai/chat
  body: { userId, sessionId, text }
  flow:
    1. local_safety_check(text) → if hit: return CRISIS payload
    2. emotion_classify(text)   → 端侧 or 云端
    3. memory_retrieve(userId, k=5)
    4. llm_stream_call(prompt)  → SSE
    5. judge_model_score(reply) → if < 0.7: fallback
    6. audit_log_async()
```

**上线闸门（硬性）**：
- 500 条高危模拟对话误放率必须 = 0
- 裁判模型召回率 ≥ 0.95 / 精确率 ≥ 0.85
- 未通过不允许灰度发版

### 6.2 高危熔断工作流

```
User Input
  ↓ L1 命中
crisis-svc
  ├─ 停止 LLM 调用
  ├─ 推送温柔浮层（不使用"危机/紧急"字样）
  ├─ 提供 3 出口：静默守护 / 安全对话 / 一键热线
  └─ 事件加密写入 crisis-event 表（法务保留 180 天）
```

## 7. 游戏子系统架构

```
Cocos Creator 项目 (TS)
├─ scenes/happy / low / angry
├─ systems/
│   ├─ InputSystem（Flutter 摇杆桥接）
│   ├─ PhysicsSystem（Box2D）
│   ├─ ParticleSystem
│   └─ AudioSystem
├─ network/
│   └─ GameBridge（向原生发送能量事件）
└─ assets/ (按模式懒加载，首包 5MB)
```

- **关卡数据**：JSON 配置 + 热更新（走 CDN + 签名校验）
- **能量上报**：闯关结束用 HMAC 签名上报，防刷
- **性能预算**：包体增量 ≤ 15MB；内存峰值 ≤ 180MB

## 8. 安全 · 隐私 · 合规

- 全链路 TLS 1.3 + 证书绑定（防中间人）
- 生成式 AI 完成**网信办深度合成备案 + 生成式 AI 备案**
- 端侧密钥：iOS Keychain Secure Enclave / Android StrongBox
- 日志脱敏：用户原文**永不进应用日志**
- 法务红线：AI 回复每日抽检 0.1% 做人工审核，发现偏差立刻触发 Red-Team 回归

## 9. 可观测性

| 维度 | 工具 |
|------|------|
| APM | OpenTelemetry + SkyWalking |
| 日志 | ELK / Loki |
| 指标 | Prometheus + Grafana |
| 崩溃 | Sentry + 自研符号表 |
| 业务漏斗 | ClickHouse + Metabase |
| AI 质量 | LangSmith 自建版 + 人工抽检面板 |

## 10. CI / CD 与发布

- Monorepo（pnpm + Melos）
- 客户端 CI：GitHub Actions → Firebase App Distribution（灰度 5% / 20% / 50% / 100%）
- 服务端：K8s + ArgoCD，灰度按用户 hash 分桶
- 灾备：同城双活 + 跨地域冷备，RTO < 30min / RPO < 5min

## 11. 部署视图（K8s 命名空间）

```
ns: edge          APISIX, Rate-Limiter
ns: app-prod      user / mood / chat / ...
ns: ai            ai-gateway, prompt-router, safety-filter
ns: data          pg-operator, redis-cluster, clickhouse
ns: ops           prometheus, grafana, sentry
ns: admin         cms, audit-queue
```

## 12. 性能 / 容量预估（假设 DAU 50 万）

- 情绪事件日均 200 万条 → ClickHouse 写入 25 rps（宽裕）
- 树洞对话日均 150 万轮 → LLM 调用峰值 200 qps → 预付 2000 并发额度
- 游戏局日均 80 万 → 能量上报 10 rps（后端无压力）
- 对象存储流量 200GB/日 → CDN 回源 5%，≈ 10GB
- 服务总核数估算：API 40 核 / AI 网关 80 核 / 数据层 128 核

## 13. 架构演进路线（12 个月）

```
M1–3 : 单体 -> 服务拆分 MVP（user / mood / chat / ai-gateway）
M4–6 : 接入游戏模块 + growth-svc + 小程序版（Taro）
M7–9 : 向量检索长期记忆 + 多 LLM Provider 热切换
M10–12: 情绪热力图 BI 平台 + 海外合规部署（新加坡 Region）
```

---

> **架构一句话总结**：以"Flutter + Cocos 混合端 + Go 微服务 + 多 LLM 网关 + 端侧隐私优先"为骨架，靠事件溯源与端侧加密守住情绪数据这条护城河。
