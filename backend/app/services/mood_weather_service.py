from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.mood_entry import MoodEntry
from app.schemas.mood_weather import (
    InviteCard,
    MoodWeatherCheckinRequest,
    MoodWeatherCheckinResponse,
)
from app.services.growth_service import award_growth

MODE_MAP = {
    "低落": "low_mode",
    "疲惫": "low_mode",
    "生气": "anger_mode",
    "开心": "joy_mode",
    "平静": "joy_mode",
    "焦虑": "low_mode",
    "low": "low_mode",
    "angry": "anger_mode",
    "joy": "joy_mode",
}

EMPATHY_MAP = {
    "low_mode": "今天像是阴下来了一点。先不用急着把自己整理好，我们先替这片天气找个安静的地方落下来。",
    "anger_mode": "这股顶在心口的劲很明显。我们先安全地把它散开一点，再慢慢把自己收回来。",
    "joy_mode": "这一刻有一点亮起来了，很值得被留下。我们可以把这点好感觉再托住一会。",
}

MODE_INVITE_TITLES = {
    "low_mode": "去云团里缓一缓",
    "anger_mode": "去把气泡散开",
    "joy_mode": "去把亮光留住",
}


def submit_checkin(
    db: Session,
    *,
    device_id: str,
    payload: MoodWeatherCheckinRequest,
) -> MoodWeatherCheckinResponse:
    normalized_emotion = payload.emotion.strip()
    recommended_mode = MODE_MAP.get(normalized_emotion, "low_mode")
    mood_entry = MoodEntry(
        device_id=device_id,
        emotion=normalized_emotion,
        intensity=payload.intensity,
        note_text=payload.note_text,
        recommended_mode=recommended_mode,
    )
    db.add(mood_entry)
    db.commit()
    db.refresh(mood_entry)
    award_growth(
        db,
        device_id=device_id,
        source_type="checkin",
        source_id=mood_entry.id,
    )

    return MoodWeatherCheckinResponse(
        checkin_id=mood_entry.id or str(uuid4()),
        empathy_text=EMPATHY_MAP[recommended_mode],
        recommended_mode=recommended_mode,
        invite_cards=[
            InviteCard(type="chat", title="说给我听", route="/treehole"),
            InviteCard(
                type="mode",
                title=MODE_INVITE_TITLES[recommended_mode],
                route=f"/mode/{recommended_mode.replace('_mode', '')}",
                mode=recommended_mode,
            ),
            InviteCard(type="blind_box", title="抽一张今天的卡", route="/blind-box"),
        ],
    )
