from datetime import datetime, timedelta, timezone
import json

from sqlalchemy import delete, desc, select
from sqlalchemy.orm import Session

from app.models.agent_profile import AgentProfile
from app.models.blind_box_draw import BlindBoxDraw
from app.models.home_whisper import HomeWhisper
from app.models.mode_session import ModeSession
from app.models.mood_entry import MoodEntry
from app.models.treehole import TreeholeSession
from app.schemas.home import HomeDuoLineResponse, HomeSummaryResponse
from app.services.growth_service import build_growth_summary
from app.services.llm_client import QwenClient
from app.services.momo_agent_service import build_home_agent_context

DEFAULT_HOME_SUMMARY = "今天想从哪里开始都可以。"
HOME_BADGE_ORDER = ["treehole", "mood_weather", "blind_box", "growth"]
WHISPER_COUNT = 3
WHISPER_TTL = timedelta(hours=8)
WHISPER_CHAR_LIMIT = 28
WHISPER_VERSION = "v2"
DUO_CHAT_COUNT = 4
DUO_CHAT_CHAR_LIMIT = 24
qwen_client = QwenClient()


def _trim_summary(text: str, limit: int = 120) -> str:
    cleaned = " ".join(text.split()).strip()
    if not cleaned:
        return DEFAULT_HOME_SUMMARY
    if len(cleaned) <= limit:
        return cleaned
    return f"{cleaned[: limit - 1].rstrip()}…"


def _build_latest_summary_candidates(
    *,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
) -> list[tuple[datetime, str, str]]:
    candidates: list[tuple[datetime, str, str]] = []

    if latest_mood is not None:
        mood_summary = latest_mood.note_text.strip() or f"最近一次情绪是 {latest_mood.emotion}。"
        candidates.append(
            (latest_mood.created_at, _trim_summary(mood_summary), "mood_weather")
        )

    if latest_blind_box is not None and latest_blind_box.card_title.strip():
        candidates.append(
            (
                latest_blind_box.created_at,
                _trim_summary(f"你抽到了一张“{latest_blind_box.card_title}”。"),
                "blind_box",
            )
        )

    if latest_mode is not None and latest_mode.result_summary.strip():
        candidates.append(
            (
                latest_mode.created_at,
                _trim_summary(latest_mode.result_summary.strip()),
                "growth",
            )
        )

    if latest_treehole is not None and latest_treehole.summary_text.strip():
        candidates.append(
            (
                latest_treehole.created_at,
                _trim_summary(latest_treehole.summary_text.strip()),
                "treehole",
            )
        )

    return candidates


def _build_entry_badges(
    *,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
) -> list[str]:
    available = {
        "treehole": latest_treehole is not None,
        "mood_weather": latest_mood is not None,
        "blind_box": latest_blind_box is not None,
        "growth": latest_mode is not None,
    }
    return [badge for badge in HOME_BADGE_ORDER if available[badge]]


def _latest_activity_time(
    *,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
) -> datetime | None:
    timestamps = [
        item.created_at
        for item in (latest_mood, latest_mode, latest_treehole, latest_blind_box)
        if item is not None
    ]
    return max(timestamps) if timestamps else None


def _build_whisper_snapshot_key(
    *,
    current_stage: str,
    agent_profile: AgentProfile | None,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
) -> str:
    latest_time = _latest_activity_time(
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
    )
    latest_marker = latest_time.isoformat() if latest_time else "empty"
    latest_emotion = latest_mood.emotion if latest_mood is not None else "none"
    profile_marker = "none"
    if agent_profile is not None:
        profile_marker = (
            f"{agent_profile.support_preference}:"
            f"{agent_profile.last_strategy}:"
            f"{agent_profile.helpful_turn_count}:"
            f"{agent_profile.updated_at.isoformat()}"
        )
    return f"{WHISPER_VERSION}:{current_stage}:{latest_emotion}:{latest_marker}:{profile_marker}"


def _load_cached_whispers(
    db: Session,
    *,
    device_id: str,
    snapshot_key: str,
) -> list[str]:
    rows = db.scalars(
        select(HomeWhisper)
        .where(
            HomeWhisper.device_id == device_id,
            HomeWhisper.snapshot_key == snapshot_key,
        )
        .order_by(HomeWhisper.sort_order.asc(), HomeWhisper.created_at.desc())
    ).all()
    if len(rows) < WHISPER_COUNT:
        return []

    created_at = rows[0].created_at
    if datetime.now(timezone.utc) - created_at > WHISPER_TTL:
        return []

    return [row.text for row in rows[:WHISPER_COUNT] if row.text.strip()]


def _build_whisper_context(
    *,
    latest_summary: str,
    agent_profile: AgentProfile | None,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
    recent_treeholes: list[TreeholeSession],
) -> str:
    parts = [f"最近首页摘要：{_trim_summary(latest_summary, 90)}"]
    if latest_mood is not None:
        note = _trim_summary(latest_mood.note_text or "", 48)
        note_part = f"；备注：{note}" if note else ""
        parts.append(
            f"最近情绪：{latest_mood.emotion}，强度 {latest_mood.intensity}/10{note_part}"
        )
    if latest_mode is not None and latest_mode.result_summary:
        parts.append(f"最近完成的小场景：{_trim_summary(latest_mode.result_summary, 72)}")
    if latest_blind_box is not None and latest_blind_box.card_title:
        parts.append(f"最近抽到的卡：{_trim_summary(latest_blind_box.card_title, 36)}")
    if latest_treehole is not None and latest_treehole.summary_text:
        parts.append(f"最近树洞方向：{_trim_summary(latest_treehole.summary_text, 90)}")

    parts.extend(build_home_agent_context(agent_profile))

    helpful_sessions = [
        item for item in recent_treeholes if item.helpful_score is not None and item.helpful_score > 0
    ]
    if helpful_sessions:
        helpful_summary = " / ".join(
            _trim_summary(item.summary_text, 42)
            for item in helpful_sessions[:2]
            if item.summary_text.strip()
        )
        if helpful_summary:
            parts.append(f"之前更接住 TA 的陪伴线索：{helpful_summary}")

    return "\n".join(parts)


def _parse_whisper_lines(raw_text: str) -> list[str]:
    cleaned = raw_text.strip()
    if not cleaned:
        return []

    try:
        parsed = json.loads(cleaned)
        if isinstance(parsed, list):
            lines = [
                _trim_summary(str(item), WHISPER_CHAR_LIMIT)
                for item in parsed
                if str(item).strip()
            ]
            return _dedupe_lines(lines)[:WHISPER_COUNT]
    except json.JSONDecodeError:
        pass

    fallback_lines = []
    for raw_line in cleaned.splitlines():
        line = raw_line.strip().lstrip("-").lstrip("•").strip()
        if not line:
            continue
        fallback_lines.append(_trim_summary(line, WHISPER_CHAR_LIMIT))
    return _dedupe_lines(fallback_lines)[:WHISPER_COUNT]


def _dedupe_lines(lines: list[str]) -> list[str]:
    seen: set[str] = set()
    unique: list[str] = []
    for raw_line in lines:
        line = raw_line.strip()
        if not line:
            continue
        normalized = line.replace("，", "").replace("。", "").replace(" ", "")
        if normalized in seen:
            continue
        seen.add(normalized)
        unique.append(line)
    return unique


def _pick_fallback_lines(candidates: list[str], *, seed_text: str) -> list[str]:
    unique_candidates = _dedupe_lines(candidates)
    if len(unique_candidates) <= WHISPER_COUNT:
        return unique_candidates[:WHISPER_COUNT]

    seed = sum(ord(ch) for ch in seed_text) % len(unique_candidates)
    ordered = unique_candidates[seed:] + unique_candidates[:seed]
    return ordered[:WHISPER_COUNT]


def _fallback_whispers(
    *,
    agent_profile: AgentProfile | None,
    latest_summary: str,
    latest_mood: MoodEntry | None,
) -> list[str]:
    emotion = latest_mood.emotion if latest_mood is not None else ""
    latest_hint = _trim_summary(latest_summary, 20)
    seed_text = f"{emotion}:{latest_hint}"
    support_preference = agent_profile.support_preference if agent_profile is not None else "listen"

    if support_preference == "quiet":
        return _pick_fallback_lines(
            [
                "先不用把一切说完整，我在这里。",
                "如果你只想安静靠一下，也算在往前。",
                "今天可以慢一点，我会陪你守着这口气。",
                "夜色还长，但你不用一个人撑着。",
                "哪怕只留下几个字，我也会认真接住。",
                f"先把最重的那一小块放下来：{latest_hint}",
            ],
            seed_text=seed_text,
        )
    if support_preference == "organize":
        return _pick_fallback_lines(
            [
                "乱的时候，我们就只捡眼前这一小块。",
                "今天不用一次弄明白，我会陪你慢慢理顺。",
                "如果脑子很满，先替你抱住一点点。",
                "先别急着解决全部，只看最卡的一处就好。",
                "我会把节奏放慢一点，陪你理出一点缝隙。",
                f"先从这件最压手的小事开始：{latest_hint}",
            ],
            seed_text=seed_text,
        )
    if support_preference == "vent":
        return _pick_fallback_lines(
            [
                "今天不用太懂事，我先站在你这边。",
                "那股闷着的火，我会先陪你托住。",
                "你可以不圆滑，也不用马上把自己压下去。",
                "如果想吐槽一点，我会稳稳地听着。",
                "委屈和不爽被看见，本身就很重要。",
                f"先把那句最扎人的话放过来：{latest_hint}",
            ],
            seed_text=seed_text,
        )

    if any(word in emotion for word in ("生气", "烦", "怒")):
        return _pick_fallback_lines(
            [
                "今天的你已经撑了很久。",
                "那股顶着你的火，我看见了。",
                "先不用把自己劝懂，我陪你站一会。",
                "如果你想吐出来一点，我会接住。",
                "风不会一下停，但你可以先靠一下。",
                f"先把最扎手的那一下放过来：{latest_hint}",
            ],
            seed_text=seed_text,
        )
    if any(word in emotion for word in ("开心", "轻松", "平静")):
        return _pick_fallback_lines(
            [
                "今天这点亮光，值得被轻轻留住。",
                "你一回来，小岛就亮了一点。",
                "这样的平静，也是一种很珍贵的光。",
                "如果愿意，我们把这份轻松多留一会。",
                "今天的风，像是在慢慢抱住你。",
                "有些好时刻，不用很大，也值得记住。",
            ],
            seed_text=seed_text,
        )
    if any(word in emotion for word in ("低落", "难受", "焦虑", "疲惫")):
        return _pick_fallback_lines(
            [
                "今天的你辛苦了。",
                "黑夜再长，也会有一点星光。",
                "我先在这里陪你，不急着变好。",
                "不用一下子整理完，我们慢一点也可以。",
                "如果现在只想被轻轻抱一下，也可以。",
                f"今天先把最重的那一小块放下来：{latest_hint}",
            ],
            seed_text=seed_text,
        )
    return _pick_fallback_lines(
        [
            "今天的你辛苦了。",
            "我会先安静地陪你一会。",
            "黑夜再长，也会有一点星光。",
            "如果一时说不清，也可以先靠近一点。",
            "今天想从哪一块开始，都算在往前。",
            f"先从这一点点开始也可以：{latest_hint}",
        ],
        seed_text=seed_text,
    )


def _trim_duo_line(text: str) -> str:
    return _trim_summary(text, DUO_CHAT_CHAR_LIMIT)


def _fallback_duo_chat(
    *,
    agent_profile: AgentProfile | None,
    latest_summary: str,
    latest_mood: MoodEntry | None,
) -> list[HomeDuoLineResponse]:
    emotion = latest_mood.emotion if latest_mood is not None else (
        agent_profile.last_emotion if agent_profile is not None else "neutral"
    )
    support_preference = (
        agent_profile.support_preference if agent_profile is not None else "listen"
    )
    latest_hint = _trim_summary(latest_summary, 18).replace("。", "")

    if any(word in emotion for word in ("生气", "烦", "怒")):
        script = [
            ("momo", "worried", "那股顶着的劲还在。"),
            ("lulu", "fired_up", "嗯，我们先站你这边，再慢慢把火放下。"),
            ("momo", "soft_smile", "不用立刻把自己劝圆。"),
            ("lulu", "cheer", "等你准备好，我们再把心口慢慢松开。"),
        ]
    elif any(word in emotion for word in ("开心", "轻松", "平静")):
        script = [
            ("momo", "happy", "今天这里亮起来了一点。"),
            ("lulu", "cheer", "那我们替他把这点亮光多留一会。"),
            ("momo", "curious", f"像“{latest_hint}”这样的时刻也值得记住。"),
            ("lulu", "soft_smile", "嗯，小小的好也可以被认真接住。"),
        ]
    elif support_preference == "organize":
        script = [
            ("momo", "curious", "今天脑子里像堆了很多线。"),
            ("lulu", "soft_smile", "那我们只帮他捡最前面这一小根。"),
            ("momo", "worried", f"先从“{latest_hint}”这一块开始。"),
            ("lulu", "cheer", "剩下的，不用一下子都弄明白。"),
        ]
    elif support_preference == "vent":
        script = [
            ("momo", "worried", "我听见那股委屈还没下去。"),
            ("lulu", "fired_up", "那就先让它被好好看见，不用急着懂事。"),
            ("momo", "softSmile", "嗯，我们先陪他把那句话放出来。"),
            ("lulu", "cheer", "说出来一点，已经是在松开了。"),
        ]
    else:
        script = [
            ("momo", "soft_smile", "今天的你辛苦了。"),
            ("lulu", "cheer", "黑夜再长，也会有一点星光。"),
            ("momo", "sleepy", f"我们先替“{latest_hint}”留个软一点的位置。"),
            ("lulu", "happy", "嗯，剩下的慢慢来也没关系。"),
        ]

    turns = [
        HomeDuoLineResponse(
            speaker=speaker,
            mood=mood,
            text=_trim_duo_line(text),
        )
        for speaker, mood, text in script[:DUO_CHAT_COUNT]
    ]
    return turns


def _normalize_duo_mood(raw: str) -> str:
    normalized = raw.strip().lower().replace("-", "_")
    allowed = {
        "soft_smile",
        "happy",
        "curious",
        "sleepy",
        "cheer",
        "sad",
        "worried",
        "fired_up",
    }
    return normalized if normalized in allowed else "soft_smile"


def _parse_duo_chat_lines(raw_text: str) -> list[HomeDuoLineResponse]:
    cleaned = raw_text.strip()
    if not cleaned:
        return []

    try:
        parsed = json.loads(cleaned)
    except json.JSONDecodeError:
        return []

    if not isinstance(parsed, list):
        return []

    expected_speakers = ["momo", "lulu", "momo", "lulu"]
    turns: list[HomeDuoLineResponse] = []
    for index, item in enumerate(parsed[:DUO_CHAT_COUNT]):
        if not isinstance(item, dict):
            continue
        speaker = str(item.get("speaker") or expected_speakers[index]).strip().lower()
        if speaker not in {"momo", "lulu"}:
            speaker = expected_speakers[index]
        text = _trim_duo_line(str(item.get("text") or ""))
        if not text:
            continue
        turns.append(
            HomeDuoLineResponse(
                speaker=speaker,
                text=text,
                mood=_normalize_duo_mood(str(item.get("mood") or "soft_smile")),
            )
        )

    if len(turns) < 2:
        return []

    normalized_turns: list[HomeDuoLineResponse] = []
    for index, turn in enumerate(turns[:DUO_CHAT_COUNT]):
        normalized_turns.append(
            HomeDuoLineResponse(
                speaker=expected_speakers[index],
                text=turn.text,
                mood=turn.mood,
            )
        )
    return normalized_turns


def _build_duo_chat_context(
    *,
    agent_profile: AgentProfile | None,
    latest_summary: str,
    latest_mood: MoodEntry | None,
) -> str:
    parts = [f"最近摘要：{_trim_summary(latest_summary, 72)}"]
    if latest_mood is not None:
        note = _trim_summary(latest_mood.note_text or "", 42)
        note_part = f"；备注：{note}" if note else ""
        parts.append(
            f"最近情绪：{latest_mood.emotion}，强度 {latest_mood.intensity}/10{note_part}"
        )
    if agent_profile is not None:
        if agent_profile.support_preference:
            parts.append(f"更喜欢被这样陪：{agent_profile.support_preference}")
        if agent_profile.relationship_note:
            parts.append(f"关系状态：{_trim_summary(agent_profile.relationship_note, 72)}")
        if agent_profile.preference_summary:
            parts.append(f"偏好线索：{_trim_summary(agent_profile.preference_summary, 72)}")
        if agent_profile.helpful_summary:
            parts.append(f"之前更被接住的方式：{_trim_summary(agent_profile.helpful_summary, 72)}")
    return "\n".join(parts)


def _generate_duo_chat_lines(
    *,
    agent_profile: AgentProfile | None,
    latest_summary: str,
    latest_mood: MoodEntry | None,
) -> list[HomeDuoLineResponse]:
    if not qwen_client.is_configured:
        return _fallback_duo_chat(
            agent_profile=agent_profile,
            latest_summary=latest_summary,
            latest_mood=latest_mood,
        )

    messages = [
        {
            "role": "system",
            "content": (
                "你要为 EmoBot 首页生成一段 4 句的双主角对话。"
                "角色只有两个：momo 和 lulu。"
                "要求严格交替：momo, lulu, momo, lulu。"
                "她们是在首页小岛上轻声聊天，像两个会陪人的治愈角色，不是播报员，不是客服。"
                "内容要围绕用户最近的情绪和状态，说得暖一点、自然一点，像真人轻声接话。"
                "不要复读，不要喊口号，不要诊断，不要说教，不要提实时新闻。"
                "每句 8 到 24 个中文字符。"
                "每条都要带 mood 字段，可选：soft_smile, happy, curious, sleepy, cheer, sad, worried, fired_up。"
                "只返回 JSON 数组，例如"
                '[{"speaker":"momo","text":"今天先慢一点。","mood":"soft_smile"}]'
            ),
        },
        {
            "role": "user",
            "content": _build_duo_chat_context(
                agent_profile=agent_profile,
                latest_summary=latest_summary,
                latest_mood=latest_mood,
            ),
        },
    ]

    try:
        raw_text = qwen_client.complete_chat(
            messages=messages,
            temperature=0.85,
            max_tokens=260,
        )
        turns = _parse_duo_chat_lines(raw_text)
        if len(turns) >= 4:
            return turns[:DUO_CHAT_COUNT]
    except Exception:  # noqa: BLE001
        pass

    return _fallback_duo_chat(
        agent_profile=agent_profile,
        latest_summary=latest_summary,
        latest_mood=latest_mood,
    )


def _generate_whisper_lines(
    *,
    agent_profile: AgentProfile | None,
    latest_summary: str,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
    recent_treeholes: list[TreeholeSession],
) -> list[str]:
    if not qwen_client.is_configured:
        return _fallback_whispers(
            agent_profile=agent_profile,
            latest_summary=latest_summary,
            latest_mood=latest_mood,
        )

    context = _build_whisper_context(
        latest_summary=latest_summary,
        agent_profile=agent_profile,
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
        recent_treeholes=recent_treeholes,
    )
    messages = [
        {
            "role": "system",
            "content": (
                "你在为 EmoBot 首页的 momo 生成 3 句可轮播的暖心短句。"
                "要求：温柔、安静、像熟悉用户的人；要有暖意，但不要鸡汤味，不要命令，不要诊断。"
                "允许一点夜色、星光、灯、海风之类的轻意象，但不要浮夸。"
                "每句 8 到 24 个中文字符，三句之间不要重复，句式开头也尽量不同。"
                "优先基于用户最近更容易被接住的方式来写，让人读起来有被轻轻抱住的感觉。"
                "只返回 JSON 数组，不要解释。"
            ),
        },
        {"role": "user", "content": context},
    ]
    try:
        raw_text = qwen_client.complete_chat(messages=messages, temperature=0.7, max_tokens=180)
        lines = _parse_whisper_lines(raw_text)
        if len(lines) >= WHISPER_COUNT:
            return lines[:WHISPER_COUNT]
    except Exception:  # noqa: BLE001
        pass

    return _fallback_whispers(
        agent_profile=agent_profile,
        latest_summary=latest_summary,
        latest_mood=latest_mood,
    )


def _store_whispers(
    db: Session,
    *,
    device_id: str,
    snapshot_key: str,
    lines: list[str],
) -> list[str]:
    usable_lines = _dedupe_lines(
        [_trim_summary(line, WHISPER_CHAR_LIMIT) for line in lines if line.strip()]
    )[:WHISPER_COUNT]
    if not usable_lines:
        return []

    db.execute(delete(HomeWhisper).where(HomeWhisper.device_id == device_id))
    db.add_all(
        [
            HomeWhisper(
                device_id=device_id,
                snapshot_key=snapshot_key,
                sort_order=index,
                text=line,
            )
            for index, line in enumerate(usable_lines)
        ]
    )
    db.commit()
    return usable_lines


def _resolve_home_whispers(
    db: Session,
    *,
    device_id: str,
    current_stage: str,
    agent_profile: AgentProfile | None,
    latest_summary: str,
    latest_mood: MoodEntry | None,
    latest_mode: ModeSession | None,
    latest_treehole: TreeholeSession | None,
    latest_blind_box: BlindBoxDraw | None,
) -> list[str]:
    snapshot_key = _build_whisper_snapshot_key(
        current_stage=current_stage,
        agent_profile=agent_profile,
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
    )

    cached = _load_cached_whispers(
        db,
        device_id=device_id,
        snapshot_key=snapshot_key,
    )
    if len(cached) >= WHISPER_COUNT:
        return cached

    recent_treeholes = db.scalars(
        select(TreeholeSession)
        .where(TreeholeSession.device_id == device_id)
        .order_by(desc(TreeholeSession.created_at))
        .limit(3)
    ).all()
    generated = _generate_whisper_lines(
        agent_profile=agent_profile,
        latest_summary=latest_summary,
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
        recent_treeholes=recent_treeholes,
    )
    return _store_whispers(
        db,
        device_id=device_id,
        snapshot_key=snapshot_key,
        lines=generated,
    )


def get_home_summary(db: Session, *, device_id: str) -> HomeSummaryResponse:
    growth = build_growth_summary(db, device_id=device_id)
    agent_profile = db.get(AgentProfile, device_id)
    latest_mood = db.scalar(
        select(MoodEntry)
        .where(MoodEntry.device_id == device_id)
        .order_by(desc(MoodEntry.created_at))
    )
    latest_mode = db.scalar(
        select(ModeSession)
        .where(ModeSession.device_id == device_id)
        .order_by(desc(ModeSession.created_at))
    )
    latest_treehole = db.scalar(
        select(TreeholeSession)
        .where(TreeholeSession.device_id == device_id)
        .order_by(desc(TreeholeSession.created_at))
    )
    latest_blind_box = db.scalar(
        select(BlindBoxDraw)
        .where(BlindBoxDraw.device_id == device_id)
        .order_by(desc(BlindBoxDraw.created_at))
    )

    candidates = _build_latest_summary_candidates(
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
    )
    latest_summary = DEFAULT_HOME_SUMMARY
    if candidates:
        latest_summary = max(candidates, key=lambda item: item[0])[1]

    entry_badges = _build_entry_badges(
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
    )
    whisper_lines = _resolve_home_whispers(
        db,
        device_id=device_id,
        current_stage=growth.current_stage,
        agent_profile=agent_profile,
        latest_summary=latest_summary,
        latest_mood=latest_mood,
        latest_mode=latest_mode,
        latest_treehole=latest_treehole,
        latest_blind_box=latest_blind_box,
    )
    duo_chat_lines = _generate_duo_chat_lines(
        agent_profile=agent_profile,
        latest_summary=latest_summary,
        latest_mood=latest_mood,
    )

    return HomeSummaryResponse(
        momo_stage=growth.current_stage,
        growth_points=growth.growth_points,
        last_summary=latest_summary,
        entry_badges=entry_badges,
        whisper_lines=whisper_lines,
        duo_chat_lines=duo_chat_lines,
        duo_chat_turn_limit=DUO_CHAT_COUNT,
    )
