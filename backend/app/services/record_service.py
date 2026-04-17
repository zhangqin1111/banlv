from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.blind_box_draw import BlindBoxDraw
from app.models.mode_session import ModeSession
from app.models.mood_entry import MoodEntry
from app.models.treehole import TreeholeSession
from app.schemas.records import RecordItem, RecordsResponse

MODE_TITLES = {
    "joy_mode": "光粒漂流",
    "low_mode": "云团呼吸",
    "anger_mode": "气泡释放",
}


def list_records(
    db: Session,
    *,
    device_id: str,
    days: int = 7,
) -> RecordsResponse:
    limit = max(1, min(days * 4, 40))
    timeline: list[tuple[object, RecordItem]] = []

    moods = db.scalars(
        select(MoodEntry)
        .where(MoodEntry.device_id == device_id)
        .order_by(desc(MoodEntry.created_at))
        .limit(limit)
    ).all()
    for entry in moods:
        subtitle = entry.note_text.strip() or f"推荐模式：{entry.recommended_mode}"
        timeline.append(
            (
                entry.created_at,
                RecordItem(
                    id=entry.id,
                    source_type="mood_weather",
                    title=f"情绪气象台 · {entry.emotion}",
                    subtitle=subtitle,
                    created_at=entry.created_at.isoformat(),
                ),
            )
        )

    sessions = db.scalars(
        select(TreeholeSession)
        .where(TreeholeSession.device_id == device_id)
        .order_by(desc(TreeholeSession.created_at))
        .limit(limit)
    ).all()
    for session in sessions:
        summary = session.summary_text.strip()
        if not summary:
            continue
        timeline.append(
            (
                session.created_at,
                RecordItem(
                    id=session.id,
                    source_type="treehole",
                    title="解忧树洞",
                    subtitle=summary,
                    created_at=session.created_at.isoformat(),
                ),
            )
        )

    mode_sessions = db.scalars(
        select(ModeSession)
        .where(ModeSession.device_id == device_id)
        .order_by(desc(ModeSession.created_at))
        .limit(limit)
    ).all()
    for session in mode_sessions:
        timeline.append(
            (
                session.created_at,
                RecordItem(
                    id=session.id,
                    source_type="mode",
                    title=f"情绪模式 · {MODE_TITLES.get(session.mode_type, session.mode_type)}",
                    subtitle=session.result_summary.strip() or "完成了一次小场景练习。",
                    created_at=session.created_at.isoformat(),
                ),
            )
        )

    blind_box_draws = db.scalars(
        select(BlindBoxDraw)
        .where(BlindBoxDraw.device_id == device_id)
        .order_by(desc(BlindBoxDraw.created_at))
        .limit(limit)
    ).all()
    for draw in blind_box_draws:
        timeline.append(
            (
                draw.created_at,
                RecordItem(
                    id=draw.id,
                    source_type="blind_box",
                    title=f"解忧盲盒 · {draw.card_title}",
                    subtitle=draw.card_body,
                    created_at=draw.created_at.isoformat(),
                ),
            )
        )

    timeline.sort(key=lambda item: item[0], reverse=True)
    return RecordsResponse(items=[item for _, item in timeline[:limit]])
