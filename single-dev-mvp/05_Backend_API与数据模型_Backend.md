# EmoBot Backend API 与数据模型

## 1. 技术栈

- Python 3.12
- FastAPI
- SQLAlchemy 2.0
- Alembic
- PostgreSQL 16
- SSE

仍然保持单体服务，不拆微服务。

---

## 2. 服务边界

```text
app/
├─ api/
│  ├─ auth.py
│  ├─ home.py
│  ├─ mood_weather.py
│  ├─ treehole.py
│  ├─ modes.py
│  ├─ blind_box.py
│  ├─ growth.py
│  ├─ records.py
│  ├─ report.py
│  └─ settings.py
├─ services/
│  ├─ home_service.py
│  ├─ mood_weather_service.py
│  ├─ treehole_service.py
│  ├─ safety_service.py
│  ├─ mode_service.py
│  ├─ blind_box_service.py
│  └─ growth_service.py
└─ models/
```

---

## 3. 数据模型

### 3.1 devices
- `id`
- `device_id`
- `anon_token_hash`
- `created_at`
- `last_active_at`

### 3.2 mood_entries
- `id`
- `device_id`
- `emotion`
- `intensity`
- `note_text`
- `recommended_mode`
- `created_at`

### 3.3 treehole_sessions
- `id`
- `device_id`
- `mood_entry_id`
- `status`
- `summary_text`
- `helpful_score`
- `created_at`
- `ended_at`

### 3.4 treehole_messages
- `id`
- `session_id`
- `role`
- `content_redacted`
- `created_at`

### 3.5 mode_sessions
- `id`
- `device_id`
- `mood_entry_id`
- `mode_type`
- `duration_sec`
- `result_summary`
- `helpful_score`
- `created_at`

### 3.6 blind_box_draws
- `id`
- `device_id`
- `mood_entry_id`
- `worry_text_redacted`
- `card_type`
- `card_title`
- `card_body`
- `is_saved`
- `created_at`

### 3.7 growth_profiles
- `device_id`
- `growth_points`
- `current_stage`
- `last_stage_updated_at`

### 3.8 growth_events
- `id`
- `device_id`
- `source_type`
- `source_id`
- `delta_points`
- `created_at`

### 3.9 crisis_events
- `id`
- `device_id`
- `source`
- `rule_hit`
- `severity`
- `created_at`

### 3.10 reports
- `id`
- `device_id`
- `source_type`
- `source_id`
- `category`
- `message`
- `created_at`

---

## 4. API 列表

### 4.1 鉴权
#### `POST /v1/auth/guest`
创建匿名身份。

### 4.2 首页摘要
#### `GET /v1/home/summary`
返回：
- `momo_stage`
- `growth_points`
- `last_summary`
- `entry_badges`

### 4.3 情绪气象台提交
#### `POST /v1/mood-weather/checkins`
请求：
```json
{
  "emotion": "low",
  "intensity": 7,
  "note_text": "今天提不起劲"
}
```

响应：
```json
{
  "checkin_id": "uuid",
  "empathy_text": "今天像是有点沉。",
  "recommended_mode": "low_mode",
  "invite_cards": [
    {"type": "chat"},
    {"type": "mode", "mode": "low_mode"},
    {"type": "blind_box"}
  ]
}
```

### 4.4 树洞会话
#### `POST /v1/treehole/sessions`

#### `POST /v1/treehole/sessions/{session_id}/stream`
SSE 事件：
- `message_start`
- `message_delta`
- `message_done`
- `safety_block`
- `error`

#### `POST /v1/treehole/sessions/{session_id}/feedback`

### 4.5 三模式会话
#### `POST /v1/modes/sessions`
```json
{
  "mood_entry_id": "uuid",
  "mode_type": "joy_mode",
  "duration_sec": 56,
  "helpful_score": 2
}
```

### 4.6 盲盒
#### `POST /v1/blind-box/draw`
```json
{
  "mood_entry_id": "uuid",
  "worry_text": "今天脑子很乱"
}
```

响应：
```json
{
  "draw_id": "uuid",
  "card_type": "gentle_reminder",
  "card_title": "先把肩膀放松一点",
  "card_body": "现在不用解决一整天，只先照顾这一分钟。"
}
```

#### `POST /v1/blind-box/{draw_id}/save`

### 4.7 Growth
#### `GET /v1/growth/summary`

#### `GET /v1/growth/events`

### 4.8 今日情绪 / 记录
#### `GET /v1/records?days=7`

### 4.9 删除
#### `DELETE /v1/records/{record_id}`

### 4.10 举报
#### `POST /v1/reports`

### 4.11 软删除账号
#### `POST /v1/settings/delete-account`

---

## 5. SSE 协议

### `message_start`
```json
{"message_id":"uuid"}
```

### `message_delta`
```json
{"message_id":"uuid","delta":"我在。"}
```

### `message_done`
```json
{"message_id":"uuid","suggestion":"low_mode"}
```

### `safety_block`
```json
{"reason":"self_harm_keyword","severity":"critical"}
```

---

## 6. 成长规则

建议固定点数：
- 情绪签到：+1
- 树洞结束：+2
- 三模式完成：+2
- 盲盒抽取：+1
- 盲盒收藏：+1

阶段：
- `seed`
- `bloom`
- `glow`

---

## 7. 盲盒内容策略

盲盒不依赖复杂生成。

首版可用“模板卡库 + 轻规则匹配”：
- gentle_reminder
- tiny_action
- small_good_thing
- breathing_tip

---

## 8. 配置项

- `DATABASE_URL`
- `JWT_SECRET`
- `LLM_API_KEY`
- `LLM_BASE_URL`
- `SENTRY_DSN`
- `SAFETY_KEYWORDS_PATH`
- `BLIND_BOX_CARDS_PATH`

---

## 9. 日志与脱敏

- 普通日志不记录完整用户原文
- 盲盒烦恼输入只保留脱敏版本
- crisis event 独立存储

---

## 10. 首版完成标准

- 首页摘要接口可用
- 气象台提交接口可用
- 树洞 SSE 可用
- 三模式会话可写入
- 盲盒抽取可用
- Growth summary 可读
- 删除 / 举报 / 高危熔断可用
