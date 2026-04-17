from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.mode_session import ModeSession
from app.schemas.modes import ModeSessionCreateRequest, ModeSessionCreateResponse
from app.services.growth_service import award_growth

MODE_SUMMARIES = {
    "joy_mode": "你把这一点轻亮留住了一会，momo 也跟着亮了一点。",
    "low_mode": "你让呼吸慢下来了一点，身体也开始没那么紧了。",
    "anger_mode": "这一阵绷紧的感觉稍微散开了一点，已经很不容易。",
}


def create_mode_session(
    db: Session,
    *,
    device_id: str,
    payload: ModeSessionCreateRequest,
) -> ModeSessionCreateResponse:
    session = ModeSession(
        device_id=device_id,
        mood_entry_id=payload.mood_entry_id,
        mode_type=payload.mode_type,
        duration_sec=payload.duration_sec,
        helpful_score=payload.helpful_score,
        result_summary=MODE_SUMMARIES.get(
            payload.mode_type,
            "这次小场景已经被轻轻记下来了。",
        ),
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    awarded_points = award_growth(
        db,
        device_id=device_id,
        source_type="mode",
        source_id=session.id,
    )

    return ModeSessionCreateResponse(
        session_id=session.id or str(uuid4()),
        mode_type=payload.mode_type,
        awarded_points=awarded_points,
        result_summary=session.result_summary,
    )
