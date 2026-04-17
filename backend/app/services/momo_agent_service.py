from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.agent_profile import AgentProfile
from app.services.llm_client import QwenClient

qwen_client = QwenClient()

MAX_AGENT_MEMORY_CHARS = 180
MAX_AGENT_FIELD_CHARS = 72


@dataclass(frozen=True)
class AgentTurnPlan:
    strategy: str
    intent: str
    primary_emotion: str
    allow_mode_suggestion: bool
    response_rules: tuple[str, ...]


def _trim_text(text: str, limit: int) -> str:
    cleaned = " ".join(text.split()).strip()
    if len(cleaned) <= limit:
        return cleaned
    return f"{cleaned[: limit - 1].rstrip()}…"


def _contains_any(text: str, keywords: tuple[str, ...]) -> bool:
    return any(keyword in text for keyword in keywords)


def get_or_create_agent_profile(db: Session, *, device_id: str) -> AgentProfile:
    profile = db.get(AgentProfile, device_id)
    if profile is not None:
        return profile

    profile = AgentProfile(
        device_id=device_id,
        relationship_note="刚刚认识你，我会先安静地接住你。",
        reflection_note="先跟着用户，不急着给方法。",
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


def relationship_stage_for_bond(bond_score: int) -> str:
    if bond_score < 4:
        return "new"
    if bond_score < 10:
        return "warm"
    return "close"


def _infer_emotion(text: str) -> str:
    lowered = text.lower()
    if _contains_any(text, ("生气", "火大", "烦死", "气炸", "憋屈", "顶不住")) or _contains_any(
        lowered,
        ("angry", "mad", "furious"),
    ):
        return "anger"
    if _contains_any(text, ("低落", "难受", "委屈", "疲惫", "撑不住", "累", "想哭")) or _contains_any(
        lowered,
        ("sad", "tired", "down"),
    ):
        return "low"
    if _contains_any(text, ("焦虑", "慌", "乱", "睡不着", "紧张", "担心")) or _contains_any(
        lowered,
        ("anxious", "panic", "worry"),
    ):
        return "anxious"
    if _contains_any(text, ("开心", "轻松", "高兴", "值得庆祝", "有点亮")) or _contains_any(
        lowered,
        ("happy", "joy", "glad"),
    ):
        return "joy"
    return "neutral"


def _infer_intent(text: str, companion_mode: str | None) -> str:
    lowered = text.lower()
    if companion_mode == "vent":
        return "vent"
    if companion_mode == "organize":
        return "organize"
    if companion_mode == "quiet":
        return "quiet"
    if _contains_any(text, ("让我骂", "想骂", "太气了", "吐槽", "烦死了")):
        return "vent"
    if _contains_any(text, ("帮我理", "帮我想", "怎么办", "怎么做", "我该怎么", "想找办法")) or _contains_any(
        lowered,
        ("what should i do", "how do i", "help me think"),
    ):
        return "organize"
    if _contains_any(text, ("先别讲道理", "先听我说", "你先听", "我就想说说")):
        return "share"
    if _contains_any(text, ("不想说太多", "先不说", "陪我待一会", "慢慢说", "我想缓缓")):
        return "quiet"
    return "share"


def _infer_explicit_preference(text: str) -> str | None:
    if _contains_any(text, ("先听我说", "你先听", "别急着给建议")):
        return "listen"
    if _contains_any(text, ("陪我骂", "想吐槽", "让我发泄")):
        return "vent"
    if _contains_any(text, ("帮我理理", "帮我分析", "帮我捋一捋")):
        return "organize"
    if _contains_any(text, ("先不说", "我想慢慢说", "陪我待一会")):
        return "quiet"
    return None


def analyze_turn(
    *,
    profile: AgentProfile,
    user_message: str,
    history_size: int,
    companion_mode: str | None,
) -> AgentTurnPlan:
    intent = _infer_intent(user_message, companion_mode)
    emotion = _infer_emotion(user_message)
    explicit_preference = _infer_explicit_preference(user_message)

    if companion_mode in {"listen", "vent", "organize", "quiet"}:
        strategy = companion_mode
    elif explicit_preference is not None:
        strategy = explicit_preference
    elif intent == "vent" or emotion == "anger":
        strategy = "vent"
    elif intent == "quiet":
        strategy = "quiet"
    elif intent == "organize":
        strategy = "organize"
    elif profile.support_preference in {"listen", "quiet"} and emotion in {"low", "anxious"}:
        strategy = profile.support_preference
    else:
        strategy = "listen"

    allow_mode_suggestion = (
        intent == "organize"
        or (emotion in {"low", "anxious"} and history_size >= 4)
        or _contains_any(user_message, ("想缓一缓", "想试试", "想做点什么"))
    )

    rule_map: dict[str, tuple[str, ...]] = {
        "listen": (
            "Start by validating the feeling instead of summarizing everything back.",
            "Stay close to the user's wording and keep the pace slow.",
            "Only invite a next step if the user sounds ready.",
        ),
        "vent": (
            "Allow anger, frustration, and unfairness to be seen without lecturing.",
            "Do not rush into breathing or calming instructions.",
            "Keep the tone sturdy and non-judgmental.",
        ),
        "organize": (
            "Help the user split the mess into one or two smaller pieces.",
            "Offer gentle structure, not a checklist from a teacher.",
            "Keep any suggestion lightweight and optional.",
        ),
        "quiet": (
            "Use fewer words, tolerate silence, and do not push for details.",
            "One soft reflective sentence is often enough.",
            "Hold space more than solving.",
        ),
    }

    return AgentTurnPlan(
        strategy=strategy,
        intent=intent,
        primary_emotion=emotion,
        allow_mode_suggestion=allow_mode_suggestion,
        response_rules=rule_map[strategy],
    )


def build_agent_system_messages(
    *,
    profile: AgentProfile,
    plan: AgentTurnPlan,
) -> list[dict[str, str]]:
    relationship_stage = relationship_stage_for_bond(profile.bond_score)
    memory_summary = profile.memory_summary or "none"
    topic_summary = profile.topic_summary or "none"
    preference_summary = profile.preference_summary or "none"
    helpful_summary = profile.helpful_summary or "none"
    relationship_note = profile.relationship_note or "Stay gentle and user-led."
    reflection_note = profile.reflection_note or "Avoid sounding like a generic self-help bot."

    return [
        {
            "role": "system",
            "content": (
                "Internal momo agent state:\n"
                f"- relationship_stage: {relationship_stage}\n"
                f"- bond_score: {profile.bond_score}\n"
                f"- preferred_comfort_style: {profile.support_preference}\n"
                f"- long_memory: {memory_summary}\n"
                f"- topic_memory: {topic_summary}\n"
                f"- preference_memory: {preference_summary}\n"
                f"- helpful_pattern: {helpful_summary}\n"
                f"- relationship_note: {relationship_note}\n"
                f"- reflection_for_next_turn: {reflection_note}\n"
                "Use this as private context only. Always reply in warm, natural, concise simplified Chinese."
            ),
        },
        {
            "role": "system",
            "content": (
                "Current turn strategy:\n"
                f"- strategy: {plan.strategy}\n"
                f"- user_intent: {plan.intent}\n"
                f"- primary_emotion: {plan.primary_emotion}\n"
                f"- allow_mode_suggestion: {'yes' if plan.allow_mode_suggestion else 'no'}\n"
                "- response_rules:\n"
                + "\n".join(f"  - {rule}" for rule in plan.response_rules)
            ),
        },
    ]


def build_home_agent_context(profile: AgentProfile | None) -> list[str]:
    if profile is None:
        return []

    parts: list[str] = []
    if profile.preference_summary.strip():
        parts.append(f"用户更容易被这样接住：{_trim_text(profile.preference_summary, MAX_AGENT_FIELD_CHARS)}")
    if profile.helpful_summary.strip():
        parts.append(f"之前有效的陪伴线索：{_trim_text(profile.helpful_summary, MAX_AGENT_FIELD_CHARS)}")
    if profile.memory_summary.strip():
        parts.append(f"长期记忆：{_trim_text(profile.memory_summary, MAX_AGENT_FIELD_CHARS)}")
    if profile.relationship_note.strip():
        parts.append(f"你们现在的关系状态：{_trim_text(profile.relationship_note, MAX_AGENT_FIELD_CHARS)}")
    return parts


def _merge_memory(*segments: str, limit: int) -> str:
    seen: set[str] = set()
    merged: list[str] = []
    for raw in segments:
        text = _trim_text(raw, limit).strip("；。 ")
        if not text:
            continue
        if text in seen:
            continue
        seen.add(text)
        merged.append(text)
    return _trim_text("；".join(merged), limit)


def _build_fallback_profile_patch(
    *,
    profile: AgentProfile,
    plan: AgentTurnPlan,
    user_message: str,
    assistant_text: str,
    session_summary: str,
) -> dict[str, str]:
    explicit_preference = _infer_explicit_preference(user_message)
    preference_summary = profile.preference_summary
    if explicit_preference == "listen":
        preference_summary = "更喜欢先被听见，不要太快给建议。"
    elif explicit_preference == "vent":
        preference_summary = "委屈或生气的时候，先允许发泄会更容易被接住。"
    elif explicit_preference == "organize":
        preference_summary = "当事情太乱时，用户希望有人帮忙轻轻理顺。"
    elif explicit_preference == "quiet":
        preference_summary = "有时不想说太多，更需要安静陪着。"
    elif not preference_summary.strip():
        default_map = {
            "listen": "先顺着用户的原话接住，会比立刻建议更有效。",
            "vent": "允许情绪被看见，比马上劝冷静更有帮助。",
            "organize": "当用户主动求助时，可以帮他把乱线拆小一点。",
            "quiet": "少一点追问，多一点陪着，会更贴近用户。",
        }
        preference_summary = default_map[plan.strategy]

    relationship_note = {
        "new": "你们还在建立安全感，先别太用力。",
        "warm": "用户已经愿意把更真实的部分交给 momo 了。",
        "close": "用户对 momo 有明显信任，可以更自然地贴近一点。",
    }[relationship_stage_for_bond(profile.bond_score)]

    reflection_note = {
        "listen": "下一轮继续贴着用户的话，不急着跳去解决。",
        "vent": "不要过早劝冷静，先允许情绪留一会。",
        "organize": "只捡最乱的一小块来理，不要把话说满。",
        "quiet": "允许停顿，保持短句和留白。",
    }[plan.strategy]

    memory_summary = _merge_memory(
        profile.memory_summary,
        profile.topic_summary,
        session_summary,
        f"这轮最在意的是：{_trim_text(user_message, 56)}",
        limit=MAX_AGENT_MEMORY_CHARS,
    )
    topic_summary = _merge_memory(
        profile.topic_summary,
        _trim_text(user_message, 56),
        _trim_text(session_summary, 56),
        limit=MAX_AGENT_FIELD_CHARS,
    )

    return {
        "memory_summary": memory_summary,
        "topic_summary": topic_summary,
        "preference_summary": _trim_text(preference_summary, MAX_AGENT_FIELD_CHARS),
        "relationship_note": _trim_text(relationship_note, MAX_AGENT_FIELD_CHARS),
        "reflection_note": _trim_text(reflection_note, MAX_AGENT_FIELD_CHARS),
        "helpful_summary": _trim_text(
            profile.helpful_summary or f"最近更接近用户的回应是：{_trim_text(assistant_text, 52)}",
            MAX_AGENT_FIELD_CHARS,
        ),
    }


async def _build_llm_profile_patch(
    *,
    profile: AgentProfile,
    plan: AgentTurnPlan,
    user_message: str,
    assistant_text: str,
    session_summary: str,
) -> dict[str, str]:
    if not qwen_client.is_configured:
        return {}

    messages = [
        {
            "role": "system",
            "content": (
                "You update the internal memory state for momo, the core companion agent of a Chinese emotional support app.\n"
                "Return JSON only with these keys: memory_summary, topic_summary, preference_summary, relationship_note, reflection_note.\n"
                "All values must be concise simplified Chinese, non-medical, warm, and under 70 Chinese characters.\n"
                "Focus on: what the user keeps caring about, what support style fits them, how the relationship currently feels, and what momo should avoid next turn."
            ),
        },
        {
            "role": "user",
            "content": (
                f"Current profile memory: {profile.memory_summary or 'none'}\n"
                f"Current topic memory: {profile.topic_summary or 'none'}\n"
                f"Current preference memory: {profile.preference_summary or 'none'}\n"
                f"Current relationship note: {profile.relationship_note or 'none'}\n"
                f"Bond score: {profile.bond_score}\n"
                f"Strategy: {plan.strategy}\n"
                f"Intent: {plan.intent}\n"
                f"Emotion: {plan.primary_emotion}\n"
                f"User said: {user_message}\n"
                f"Momo replied: {assistant_text}\n"
                f"Session summary: {session_summary or 'none'}"
            ),
        },
    ]

    raw_text = await qwen_client.complete_chat_async(
        messages=messages,
        temperature=0.35,
        max_tokens=220,
    )
    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError:
        return {}

    if not isinstance(parsed, dict):
        return {}

    cleaned: dict[str, str] = {}
    for key in (
        "memory_summary",
        "topic_summary",
        "preference_summary",
        "relationship_note",
        "reflection_note",
    ):
        value = parsed.get(key)
        if isinstance(value, str) and value.strip():
            cleaned[key] = _trim_text(value, MAX_AGENT_FIELD_CHARS if key != "memory_summary" else MAX_AGENT_MEMORY_CHARS)
    return cleaned


async def update_profile_after_reply(
    db: Session,
    *,
    profile: AgentProfile,
    plan: AgentTurnPlan,
    user_message: str,
    assistant_text: str,
    session_summary: str,
    mode_suggestion: str | None,
) -> None:
    explicit_preference = _infer_explicit_preference(user_message)
    if explicit_preference is not None:
        profile.support_preference = explicit_preference
    elif profile.turn_count == 0:
        profile.support_preference = plan.strategy

    profile.turn_count += 1
    profile.last_strategy = plan.strategy
    profile.last_intent = plan.intent
    profile.last_emotion = plan.primary_emotion
    profile.last_mode_suggestion = mode_suggestion
    profile.bond_score = min(
        18,
        profile.bond_score + (2 if len(user_message.strip()) >= 18 else 1),
    )

    patch = _build_fallback_profile_patch(
        profile=profile,
        plan=plan,
        user_message=user_message,
        assistant_text=assistant_text,
        session_summary=session_summary,
    )
    try:
        llm_patch = await _build_llm_profile_patch(
            profile=profile,
            plan=plan,
            user_message=user_message,
            assistant_text=assistant_text,
            session_summary=session_summary,
        )
        patch.update(llm_patch)
    except Exception:  # noqa: BLE001
        pass

    profile.memory_summary = patch["memory_summary"]
    profile.topic_summary = patch["topic_summary"]
    profile.preference_summary = patch["preference_summary"]
    profile.relationship_note = patch["relationship_note"]
    profile.reflection_note = patch["reflection_note"]
    profile.helpful_summary = patch.get("helpful_summary", profile.helpful_summary)
    profile.updated_at = datetime.now(timezone.utc)

    db.add(profile)
    db.commit()


def update_profile_after_feedback(
    db: Session,
    *,
    profile: AgentProfile,
    helpful_score: int,
    session_summary: str,
) -> None:
    if helpful_score > 0:
        profile.helpful_turn_count += 1
        profile.bond_score = min(20, profile.bond_score + 1)
        profile.support_preference = profile.last_strategy or profile.support_preference
        profile.helpful_summary = _merge_memory(
            profile.helpful_summary,
            f"更有效的陪伴方式偏向：{profile.support_preference}",
            _trim_text(session_summary, 60),
            limit=MAX_AGENT_FIELD_CHARS,
        )
        profile.reflection_note = "保持这种节奏，先接住再轻轻往前。"
    else:
        profile.reflection_note = "下一轮减少模板感和解决感，先贴近用户原话。"
        if profile.last_strategy == "organize":
            profile.support_preference = "listen"

    profile.updated_at = datetime.now(timezone.utc)
    db.add(profile)
    db.commit()
