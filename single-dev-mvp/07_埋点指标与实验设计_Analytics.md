# EmoBot 埋点指标与实验设计

## 1. 埋点目标

首月重点看：
1. 用户有没有完成首个闭环
2. 用户会不会在不同情绪下再次回来
3. 三模式、盲盒、成长是否形成差异化留存

---

## 2. 核心事件

- `screen_view`
- `home_entry_clicked`
- `mood_weather_submitted`
- `invite_chat_selected`
- `invite_mode_selected`
- `invite_blind_box_selected`
- `treehole_message_sent`
- `treehole_response_completed`
- `mode_started`
- `mode_completed`
- `blind_box_draw_started`
- `blind_box_draw_completed`
- `blind_box_saved`
- `growth_stage_viewed`
- `session_feedback_submitted`
- `safety_block_triggered`

---

## 3. 关键字段

- `device_uid`
- `emotion`
- `intensity`
- `recommended_mode`
- `mode_type`
- `helpful_score`
- `growth_stage`

---

## 4. 核心漏斗

### 4.1 气象台漏斗
1. `screen_view(mood_weather)`
2. `mood_weather_submitted`
3. `invite_chat_selected` / `invite_mode_selected` / `invite_blind_box_selected`
4. 对应模块完成
5. `session_feedback_submitted`

### 4.2 首页入口漏斗
1. `screen_view(home)`
2. `home_entry_clicked`
3. 模块完成

---

## 5. 核心指标

- 激活率
- D1 / D7 / D30 留存
- 三模式使用率
- 三模式完成率
- 盲盒使用率
- 盲盒收藏率
- 成长阶段推进率
- 有帮助占比
- 高危触发率
- 单留存用户 AI 成本

---

## 6. 最小实验

### 实验 A：气象台邀请卡顺序
- A：聊一聊在第一个
- B：推荐模式在第一个

### 实验 B：首页四入口排列
- A：树洞优先
- B：情绪气象台优先

---

## 7. 日报模板

- 新增激活用户
- D1 留存
- D7 留存
- 三模式使用率
- 盲盒使用率
- 有帮助占比
- 高危触发率
- AI 成本
