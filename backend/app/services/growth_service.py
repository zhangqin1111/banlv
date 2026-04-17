from datetime import datetime, timezone

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.growth import GrowthEvent, GrowthProfile
from app.schemas.growth import GrowthEventItem, GrowthSummaryResponse

POINT_RULES = {
    "checkin": 1,
    "treehole": 2,
    "mode": 2,
    "blind_box": 1,
}


def stage_for_points(points: int) -> tuple[str, int]:
    if points < 10:
        return "seed", 10
    if points < 30:
        return "bloom", 30
    return "glow", 60


def get_or_create_growth_profile(db: Session, device_id: str) -> GrowthProfile:
    profile = db.get(GrowthProfile, device_id)
    if profile is not None:
        return profile

    profile = GrowthProfile(device_id=device_id, growth_points=0, current_stage="seed")
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


def award_growth(
    db: Session,
    *,
    device_id: str,
    source_type: str,
    source_id: str,
) -> int:
    delta = POINT_RULES[source_type]
    profile = get_or_create_growth_profile(db, device_id)
    profile.growth_points += delta
    stage, _ = stage_for_points(profile.growth_points)
    profile.current_stage = stage
    profile.last_stage_updated_at = datetime.now(timezone.utc)
    db.add(
        GrowthEvent(
            device_id=device_id,
            source_type=source_type,
            source_id=source_id,
            delta_points=delta,
        )
    )
    db.commit()
    return delta


def build_growth_summary(
    db: Session,
    *,
    device_id: str,
) -> GrowthSummaryResponse:
    profile = get_or_create_growth_profile(db, device_id)
    stage, next_stage_at = stage_for_points(profile.growth_points)
    events = db.scalars(
        select(GrowthEvent)
        .where(GrowthEvent.device_id == device_id)
        .order_by(desc(GrowthEvent.created_at))
        .limit(10)
    ).all()

    return GrowthSummaryResponse(
        growth_points=profile.growth_points,
        current_stage=stage,
        next_stage_at=next_stage_at,
        recent_events=[
            GrowthEventItem(
                source_type=event.source_type,
                delta_points=event.delta_points,
                created_at=(
                    event.created_at.replace(tzinfo=timezone.utc)
                    if event.created_at.tzinfo is None
                    else event.created_at.astimezone(timezone.utc)
                ).isoformat(),
            )
            for event in events
        ],
    )
