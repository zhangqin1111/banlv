import asyncio
import json
import re
from uuid import uuid4

from sqlalchemy import asc, select
from sqlalchemy.orm import Session

from app.models.crisis_event import CrisisEvent
from app.models.mood_entry import MoodEntry
from app.models.treehole import TreeholeMessage, TreeholeSession
from app.schemas.common import StatusResponse
from app.schemas.treehole import (
    TreeholeFeedbackRequest,
    TreeholeMessageItem,
    TreeholeMessagesResponse,
    TreeholeReplyResponse,
    TreeholeSessionCreateRequest,
    TreeholeSessionCreateResponse,
)
from app.services.growth_service import award_growth
from app.services.llm_client import QwenClient
from app.services.momo_agent_service import (
    AgentTurnPlan,
    analyze_turn,
    build_agent_system_messages,
    get_or_create_agent_profile,
    update_profile_after_feedback,
    update_profile_after_reply,
)
from app.services.safety_service import detect_high_risk

TREEHOLE_SYSTEM_PROMPT = """
你是 EmoBot 里的树洞陪伴者。

安全边界：
- 不做诊断，不给治疗承诺，不假装医疗或紧急支持。
- 不鼓励依赖，不使用羞耻、指责、抛弃感的话术。
- 一旦涉及自伤、自杀、伤害他人或明确危机，只做简短安抚，并建议联系现实支持。

语气与身份：
- 温柔、安静、简短、稳定。
- 像一个陪用户慢慢待一会的人，不像老师，也不像客服。
- 先接住情绪，再给一个很轻的下一步。

回复结构：
- 通常 2 到 4 句。
- 第一句先回应当下感受，不复述太多细节。
- 第二句可以帮用户把心里的结稍微理清一点。
- 只有在合适时，最后一句才邀请去一个对应的小场景，而且一定是“如果你愿意”。
- 不要把“深呼吸几次”“先冷静一下”当默认答案。
- 如果上一轮已经提过场景或呼吸，这一轮不要重复。
""".strip()

TREEHOLE_MEMORY_PROMPT = """
你在为 EmoBot 压缩一段树洞会话记忆，供下一轮继续陪伴使用。

目标：
1. 只保留继续聊天真正有用的点。
2. 写成 2 到 3 句中文短摘要，总长度不超过 140 字。
3. 包含：用户最近反复在意的事、当前主要情绪、什么回应方式更容易接住 TA。

限制：
- 不要流水账。
- 不要诊断，不要评价用户。
- 不要出现“用户说”“助手说”这类标签。
""".strip()

MAX_CONTEXT_MESSAGES = 6
MAX_MESSAGE_CHARS = 280
MAX_SUMMARY_CHARS = 220
MAX_SUMMARY_HISTORY_CHARS = 360
MAX_MEMORY_OUTPUT_CHARS = 140
MAX_MEMORY_TRANSCRIPT_CHARS = 900
MAX_MOOD_NOTE_CHARS = 80
MEMORY_REFRESH_TRIGGER_MESSAGES = 8
RECENT_MEMORY_TAIL = 4
FALLBACK_ERROR_TEXT = "现在这段连接有点不稳，我们先慢一点也可以。"

qwen_client = QwenClient()

COMPANION_MODE_PROMPTS = {
    "listen": (
        "当前陪伴方式：听你说。"
        "重点是安静倾听、轻轻接住，不急着分析，也不要太快给办法。"
    ),
    "vent": (
        "当前陪伴方式：陪你骂一会。"
        "重点是允许委屈、生气和不爽被看见，不说教，不立刻让用户冷静。"
    ),
    "organize": (
        "当前陪伴方式：帮你理一理。"
        "重点是把乱的事拆成两三块，帮用户看清，不要像老师布置任务。"
    ),
    "quiet": (
        "当前陪伴方式：先不说也可以。"
        "接受很短、零碎、沉默式表达。用更少的话回应，不追问。"
    ),
}


def create_session(
    db: Session,
    *,
    device_id: str,
    payload: TreeholeSessionCreateRequest,
) -> TreeholeSessionCreateResponse:
    session = TreeholeSession(
        device_id=device_id,
        mood_entry_id=payload.mood_entry_id,
        summary_text=_trim_text(payload.opener or "", MAX_SUMMARY_CHARS),
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return TreeholeSessionCreateResponse(session_id=session.id)


def _sse_event(event: str, payload: dict[str, str]) -> str:
    return f"event: {event}\ndata: {json.dumps(payload, ensure_ascii=False)}\n\n"


def _trim_text(text: str, limit: int) -> str:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if len(cleaned) <= limit:
        return cleaned
    return f"{cleaned[: limit - 1].rstrip()}…"


def _get_session(db: Session, *, device_id: str, session_id: str) -> TreeholeSession | None:
    return db.scalar(
        select(TreeholeSession).where(
            TreeholeSession.id == session_id,
            TreeholeSession.device_id == device_id,
        )
    )


def _load_session_history(db: Session, *, session_id: str) -> list[TreeholeMessage]:
    return db.scalars(
        select(TreeholeMessage)
        .where(TreeholeMessage.session_id == session_id)
        .order_by(asc(TreeholeMessage.created_at))
    ).all()


def _build_mood_snapshot(
    db: Session,
    *,
    device_id: str,
    mood_entry_id: str | None,
) -> str:
    mood_entry = None
    if mood_entry_id:
        mood_entry = db.scalar(
            select(MoodEntry).where(
                MoodEntry.id == mood_entry_id,
                MoodEntry.device_id == device_id,
            )
        )
    if mood_entry is None:
        mood_entry = db.scalar(
            select(MoodEntry)
            .where(MoodEntry.device_id == device_id)
            .order_by(MoodEntry.created_at.desc())
            .limit(1)
        )
    if mood_entry is None:
        return ""

    note = _trim_text(mood_entry.note_text or "", MAX_MOOD_NOTE_CHARS)
    note_part = f"；备注：{note}" if note else ""
    return (
        f"当前情绪快照：{mood_entry.emotion}，强度 {mood_entry.intensity}/10，"
        f"最近更像 {mood_entry.recommended_mode}{note_part}。"
    )


def _build_preference_snapshot(db: Session, *, device_id: str) -> str:
    helpful_sessions = db.scalars(
        select(TreeholeSession)
        .where(
            TreeholeSession.device_id == device_id,
            TreeholeSession.helpful_score.is_not(None),
            TreeholeSession.helpful_score > 0,
        )
        .order_by(TreeholeSession.created_at.desc())
        .limit(2)
    ).all()
    if not helpful_sessions:
        return ""

    summaries = [
        _trim_text(session.summary_text, 90)
        for session in helpful_sessions
        if session.summary_text.strip()
    ]
    if not summaries:
        return ""
    return f"过去更能接住 TA 的陪伴线索：{' | '.join(summaries)}"


def _build_message_history(
    db: Session,
    *,
    device_id: str,
    session: TreeholeSession,
    agent_messages: list[dict[str, str]] | None = None,
    companion_mode: str | None = None,
) -> list[dict[str, str]]:
    history = _load_session_history(db, session_id=session.id)
    mood_snapshot = _build_mood_snapshot(
        db,
        device_id=device_id,
        mood_entry_id=session.mood_entry_id,
    )
    preference_snapshot = _build_preference_snapshot(db, device_id=device_id)

    messages: list[dict[str, str]] = [{"role": "system", "content": TREEHOLE_SYSTEM_PROMPT}]
    if companion_mode and companion_mode in COMPANION_MODE_PROMPTS:
        messages.append({"role": "system", "content": COMPANION_MODE_PROMPTS[companion_mode]})
    if agent_messages:
        messages.extend(agent_messages)
    if preference_snapshot:
        messages.append({"role": "system", "content": preference_snapshot})
    if mood_snapshot:
        messages.append({"role": "system", "content": mood_snapshot})
    if session.summary_text.strip():
        messages.append(
            {
                "role": "system",
                "content": f"本次树洞摘要：{_trim_text(session.summary_text, MAX_SUMMARY_HISTORY_CHARS)}",
            }
        )
    for item in history[-MAX_CONTEXT_MESSAGES:]:
        messages.append(
            {
                "role": item.role,
                "content": _trim_text(item.content_redacted, MAX_MESSAGE_CHARS),
            }
        )
    return messages


def _fallback_reply_chunks(companion_mode: str | None) -> list[str]:
    if companion_mode == "vent":
        return [
            "这一阵窝火确实挺顶的。",
            "你不用立刻把自己劝住，",
            "先把那股不爽说出来也可以。",
        ]
    if companion_mode == "organize":
        return [
            "我先陪你把这团乱线理一理。",
            "我们只看最卡住你的那一块，",
            "别的先不用一起扛。",
        ]
    if companion_mode == "quiet":
        return [
            "不用一下子说很多。",
            "哪怕只留几个字，",
            "我也会在这里接住你。",
        ]
    return [
        "听起来，",
        "你心里现在压着的东西有点多。",
        "我们先只看眼前这一小段，",
        "好不好？",
    ]


async def _fallback_reply(_: str, companion_mode: str | None = None):
    for chunk in _fallback_reply_chunks(companion_mode):
        await asyncio.sleep(0.18)
        yield chunk


def _message_mentions_mode_or_breathing(text: str) -> bool:
    keywords = (
        "呼吸",
        "缓一缓",
        "小场景",
        "云团",
        "气泡",
        "光粒",
        "anger_mode",
        "joy_mode",
        "low_mode",
    )
    return any(word in text for word in keywords)


def _wants_specific_help(text: str) -> bool:
    lowered = text.lower()
    keywords = (
        "怎么办",
        "怎么做",
        "怎么缓",
        "怎么调整",
        "有什么办法",
        "做点什么",
        "我该怎么",
        "想缓缓",
        "想试试",
        "想做点什么",
        "help",
        "what should i do",
        "how do i",
    )
    return any(word in text for word in keywords) or any(word in lowered for word in keywords)


def _has_repeated_pressure(history: list[TreeholeMessage], text: str) -> bool:
    recent_user_messages = [item.content_redacted for item in history if item.role == "user"][-2:]
    if len(recent_user_messages) < 2:
        return False

    combined = " ".join(recent_user_messages + [text])
    repeated_keywords = (
        "累",
        "烦",
        "焦虑",
        "睡不着",
        "压",
        "压力",
        "委屈",
        "难受",
        "生气",
    )
    hits = sum(1 for word in repeated_keywords if word in combined)
    return hits >= 2


def _is_recall_request(text: str) -> bool:
    lowered = text.lower()
    keywords = (
        "我说过",
        "我刚刚说过",
        "你记得",
        "你还记得",
        "我提过",
        "我刚才在说什么",
        "我刚刚在说什么",
        "我都说了什么",
        "我说过啥",
        "记得我说的",
        "what did i say",
        "do you remember",
        "remember what i said",
    )
    return any(word in text for word in keywords) or any(word in lowered for word in keywords)


def _build_recall_reply(history: list[TreeholeMessage]) -> str | None:
    recent_user_lines = [
        _trim_text(item.content_redacted, 46)
        for item in history
        if item.role == "user" and item.content_redacted.strip()
    ][-3:]
    if not recent_user_lines:
        return None

    if len(recent_user_lines) == 1:
        summary = f"我记得你刚才提到的是：{recent_user_lines[0]}。"
    elif len(recent_user_lines) == 2:
        summary = f"我记得你刚才主要在说两件事：{recent_user_lines[0]}；还有 {recent_user_lines[1]}。"
    else:
        summary = (
            "我记得你这几句里反复绕着这些点："
            f"{recent_user_lines[0]}；{recent_user_lines[1]}；还有 {recent_user_lines[2]}。"
        )

    return (
        f"{summary}"
        "如果你愿意，我们可以挑现在最扎心的那一段，慢慢继续。"
    )


def _suggest_mode(text: str, *, history: list[TreeholeMessage]) -> str | None:
    lowered = text.lower()
    recent_assistant_text = " ".join(
        item.content_redacted for item in history if item.role == "assistant"
    )[-240:]

    if _message_mentions_mode_or_breathing(recent_assistant_text):
        return None

    if any(word in text for word in ("生气", "火大", "气死", "烦死", "紧绷", "压不住")):
        return "anger_mode"
    if any(word in text for word in ("开心", "轻松", "高兴", "有点亮", "值得庆祝")):
        return "joy_mode"
    if any(word in lowered for word in ("angry", "mad")):
        return "anger_mode"
    if any(word in lowered for word in ("happy", "joy")):
        return "joy_mode"

    if _wants_specific_help(text) or _has_repeated_pressure(history, text):
        if any(
            word in text
            for word in ("低落", "疲惫", "焦虑", "乱", "睡不着", "撑不住", "很累", "难受")
        ):
            return "low_mode"

    return None


def _record_safety_block(
    db: Session,
    *,
    device_id: str,
    safety_reason: str,
    safety_severity: str,
) -> None:
    db.add(
        CrisisEvent(
            device_id=device_id,
            source="treehole",
            rule_hit=safety_reason,
            severity=safety_severity,
        )
    )
    db.commit()


def _append_user_message(
    db: Session,
    *,
    session_id: str,
    content: str,
) -> None:
    db.add(
        TreeholeMessage(
            session_id=session_id,
            role="user",
            content_redacted=content,
        )
    )
    db.commit()


def _merge_recent_exchange(
    previous_summary: str,
    *,
    user_message: str,
    assistant_text: str,
) -> str:
    segments: list[str] = []
    if previous_summary.strip():
        segments.append(_trim_text(previous_summary, MAX_SUMMARY_HISTORY_CHARS))
    segments.append(f"现在最在意的是：{_trim_text(user_message, MAX_SUMMARY_CHARS)}")
    segments.append(f"刚才更接近的回应是：{_trim_text(assistant_text, MAX_SUMMARY_CHARS)}")
    return _trim_text("；".join(segments[-2:]), MAX_SUMMARY_HISTORY_CHARS)


def _store_assistant_reply(
    db: Session,
    *,
    session: TreeholeSession,
    user_message: str,
    assistant_text: str,
) -> None:
    if not assistant_text:
        return

    db.add(
        TreeholeMessage(
            session_id=session.id,
            role="assistant",
            content_redacted=assistant_text[:4000],
        )
    )
    session.summary_text = _merge_recent_exchange(
        session.summary_text,
        user_message=user_message,
        assistant_text=assistant_text,
    )
    db.commit()


def _build_memory_transcript(
    history: list[TreeholeMessage],
    *,
    previous_summary: str,
) -> str:
    segments: list[str] = []
    if previous_summary.strip():
        segments.append(f"已有摘要：{_trim_text(previous_summary, 180)}")

    older_history = history[:-RECENT_MEMORY_TAIL] if len(history) > RECENT_MEMORY_TAIL else history
    if not older_history:
        older_history = history

    for item in older_history[-8:]:
        role = "用户" if item.role == "user" else "陪伴"
        segments.append(f"{role}：{_trim_text(item.content_redacted, 100)}")

    return _trim_text("\n".join(segments), MAX_MEMORY_TRANSCRIPT_CHARS)


def _fallback_memory_summary(
    history: list[TreeholeMessage],
    *,
    previous_summary: str,
) -> str:
    recent_user_lines = [
        _trim_text(item.content_redacted, 56)
        for item in history
        if item.role == "user"
    ][-3:]
    recent_assistant_lines = [
        _trim_text(item.content_redacted, 48)
        for item in history
        if item.role == "assistant"
    ][-2:]

    parts: list[str] = []
    if recent_user_lines:
        parts.append(f"最近你反复卡在：{' / '.join(recent_user_lines)}")
    if recent_assistant_lines:
        parts.append(f"更接近你的回应是：{recent_assistant_lines[-1]}")
    if previous_summary.strip():
        parts.append(_trim_text(previous_summary, 80))
    return _trim_text("；".join(parts), MAX_MEMORY_OUTPUT_CHARS)


async def _refresh_session_memory(
    db: Session,
    *,
    session: TreeholeSession,
    history: list[TreeholeMessage],
) -> None:
    if len(history) < MEMORY_REFRESH_TRIGGER_MESSAGES:
        return

    transcript = _build_memory_transcript(history, previous_summary=session.summary_text)
    if not transcript:
        return

    summary_text = ""
    if qwen_client.is_configured:
        try:
            summary_text = await qwen_client.complete_chat_async(
                messages=[
                    {"role": "system", "content": TREEHOLE_MEMORY_PROMPT},
                    {"role": "user", "content": transcript},
                ],
                temperature=0.35,
                max_tokens=160,
            )
        except Exception:  # noqa: BLE001
            summary_text = ""

    if not summary_text:
        summary_text = _fallback_memory_summary(history, previous_summary=session.summary_text)

    compacted = _trim_text(summary_text, MAX_MEMORY_OUTPUT_CHARS)
    if compacted and compacted != session.summary_text:
        session.summary_text = compacted
        db.commit()


async def _collect_reply_chunks(
    db: Session,
    *,
    device_id: str,
    session: TreeholeSession,
    user_message: str,
    agent_messages: list[dict[str, str]] | None = None,
    companion_mode: str | None = None,
):
    stream = (
        qwen_client.stream_chat(
            messages=_build_message_history(
                db,
                device_id=device_id,
                session=session,
                agent_messages=agent_messages,
                companion_mode=companion_mode,
            ),
            temperature=0.55,
            max_tokens=220,
        )
        if qwen_client.is_configured
        else _fallback_reply(user_message, companion_mode)
    )
    async for chunk in stream:
        yield chunk


async def _generate_reply_text(
    db: Session,
    *,
    device_id: str,
    session: TreeholeSession,
    user_message: str,
    agent_messages: list[dict[str, str]] | None = None,
    companion_mode: str | None = None,
) -> str:
    chunks: list[str] = []
    try:
        async for chunk in _collect_reply_chunks(
            db,
            device_id=device_id,
            session=session,
            user_message=user_message,
            agent_messages=agent_messages,
            companion_mode=companion_mode,
        ):
            chunks.append(chunk)
    except Exception:  # noqa: BLE001
        if not chunks:
            async for chunk in _fallback_reply(user_message, companion_mode):
                chunks.append(chunk)
    return "".join(chunks).strip()


async def reply_once(
    db: Session,
    *,
    device_id: str,
    session_id: str,
    message: str,
    companion_mode: str | None = None,
) -> TreeholeReplyResponse:
    session = _get_session(db, device_id=device_id, session_id=session_id)
    if session is None:
        return TreeholeReplyResponse(session_id=session_id, status="missing")
    profile = get_or_create_agent_profile(db, device_id=device_id)

    safety = detect_high_risk(message)
    if safety.blocked:
        _record_safety_block(
            db,
            device_id=device_id,
            safety_reason=safety.reason,
            safety_severity=safety.severity,
        )
        return TreeholeReplyResponse(
            session_id=session_id,
            blocked=True,
            reason=safety.reason,
            severity=safety.severity,
            status="blocked",
        )

    normalized_message = _trim_text(message, 4000)
    history = _load_session_history(db, session_id=session.id)
    turn_plan = analyze_turn(
        profile=profile,
        user_message=normalized_message,
        history_size=len(history),
        companion_mode=companion_mode,
    )
    agent_messages = build_agent_system_messages(profile=profile, plan=turn_plan)
    if not session.summary_text.strip():
        await _refresh_session_memory(db, session=session, history=history)

    _append_user_message(db, session_id=session_id, content=normalized_message)
    recall_reply = (
        _build_recall_reply(history)
        if _is_recall_request(normalized_message)
        else None
    )
    assistant_text = recall_reply or await _generate_reply_text(
        db,
        device_id=device_id,
        session=session,
        user_message=normalized_message,
        agent_messages=agent_messages,
        companion_mode=companion_mode,
    )
    message_id = str(uuid4())
    raw_suggestion = None if recall_reply else _suggest_mode(normalized_message, history=history)
    suggestion = (
        raw_suggestion
        if turn_plan.allow_mode_suggestion and raw_suggestion != profile.last_mode_suggestion
        else None
    )

    if not assistant_text:
        assistant_text = FALLBACK_ERROR_TEXT

    _store_assistant_reply(
        db,
        session=session,
        user_message=normalized_message,
        assistant_text=assistant_text,
    )
    await _refresh_session_memory(
        db,
        session=session,
        history=_load_session_history(db, session_id=session.id),
    )
    await update_profile_after_reply(
        db,
        profile=profile,
        plan=turn_plan,
        user_message=normalized_message,
        assistant_text=assistant_text,
        session_summary=session.summary_text,
        mode_suggestion=suggestion,
    )

    return TreeholeReplyResponse(
        session_id=session_id,
        message_id=message_id,
        message=assistant_text,
        suggestion=suggestion,
    )


async def stream_reply(
    db: Session,
    *,
    device_id: str,
    session_id: str,
    message: str,
    companion_mode: str | None = None,
):
    session = _get_session(db, device_id=device_id, session_id=session_id)
    profile = get_or_create_agent_profile(db, device_id=device_id)
    if session is None:
        yield _sse_event("error", {"message": "会话不存在或已经失效。"})
        return

    safety = detect_high_risk(message)
    if safety.blocked:
        _record_safety_block(
            db,
            device_id=device_id,
            safety_reason=safety.reason,
            safety_severity=safety.severity,
        )
        yield _sse_event(
            "safety_block",
            {"reason": safety.reason, "severity": safety.severity},
        )
        return

    normalized_message = _trim_text(message, 4000)
    history = _load_session_history(db, session_id=session.id)
    turn_plan = analyze_turn(
        profile=profile,
        user_message=normalized_message,
        history_size=len(history),
        companion_mode=companion_mode,
    )
    agent_messages = build_agent_system_messages(profile=profile, plan=turn_plan)
    if not session.summary_text.strip():
        await _refresh_session_memory(db, session=session, history=history)

    _append_user_message(db, session_id=session_id, content=normalized_message)

    message_id = str(uuid4())
    yield _sse_event("message_start", {"message_id": message_id})

    buffer: list[str] = []
    recall_reply = (
        _build_recall_reply(history)
        if _is_recall_request(normalized_message)
        else None
    )
    raw_suggestion = None if recall_reply else _suggest_mode(normalized_message, history=history)
    suggestion = (
        raw_suggestion
        if turn_plan.allow_mode_suggestion and raw_suggestion != profile.last_mode_suggestion
        else None
    )
    if recall_reply:
        for chunk in _trim_text(recall_reply, 220).split("，"):
            if not chunk:
                continue
            piece = chunk if chunk.endswith(("。", "！", "？")) else f"{chunk}，"
            buffer.append(piece)
            yield _sse_event("message_delta", {"message_id": message_id, "delta": piece})
    else:
        try:
            async for chunk in _collect_reply_chunks(
                db,
                device_id=device_id,
                session=session,
                user_message=normalized_message,
                agent_messages=agent_messages,
                companion_mode=companion_mode,
            ):
                buffer.append(chunk)
                yield _sse_event("message_delta", {"message_id": message_id, "delta": chunk})
        except Exception as exc:  # noqa: BLE001
            yield _sse_event("error", {"message": f"模型暂时没有接稳：{exc}"})
            if not buffer:
                async for chunk in _fallback_reply(message, companion_mode):
                    buffer.append(chunk)
                    yield _sse_event(
                        "message_delta",
                        {"message_id": message_id, "delta": chunk},
                    )

    assistant_text = "".join(buffer).strip() or FALLBACK_ERROR_TEXT
    _store_assistant_reply(
        db,
        session=session,
        user_message=normalized_message,
        assistant_text=assistant_text,
    )
    await _refresh_session_memory(
        db,
        session=session,
        history=_load_session_history(db, session_id=session.id),
    )
    await update_profile_after_reply(
        db,
        profile=profile,
        plan=turn_plan,
        user_message=normalized_message,
        assistant_text=assistant_text,
        session_summary=session.summary_text,
        mode_suggestion=suggestion,
    )

    yield _sse_event(
        "message_done",
        {"message_id": message_id, "suggestion": suggestion},
    )


def save_feedback(
    db: Session,
    *,
    device_id: str,
    session_id: str,
    payload: TreeholeFeedbackRequest,
) -> StatusResponse:
    session = _get_session(db, device_id=device_id, session_id=session_id)
    if session is None:
        return StatusResponse(status="missing")
    profile = get_or_create_agent_profile(db, device_id=device_id)

    should_award = session.helpful_score is None
    session.helpful_score = payload.helpful_score
    session.status = "done"
    db.commit()
    update_profile_after_feedback(
        db,
        profile=profile,
        helpful_score=payload.helpful_score,
        session_summary=session.summary_text,
    )
    if should_award and payload.helpful_score > 0:
        award_growth(
            db,
            device_id=device_id,
            source_type="treehole",
            source_id=session.id,
        )
    return StatusResponse(status="saved")


def get_messages(
    db: Session,
    *,
    device_id: str,
    session_id: str,
) -> TreeholeMessagesResponse:
    session = _get_session(db, device_id=device_id, session_id=session_id)
    if session is None:
        return TreeholeMessagesResponse(session_id=session_id, items=[])

    items = _load_session_history(db, session_id=session_id)
    return TreeholeMessagesResponse(
        session_id=session_id,
        items=[
            TreeholeMessageItem(
                role=item.role,
                content=item.content_redacted,
                created_at=item.created_at.isoformat(),
            )
            for item in items
        ],
    )
