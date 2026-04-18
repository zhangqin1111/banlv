from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.ai_budget_event import AIBudgetEvent

settings = get_settings()
CHINA_TZ = timezone(timedelta(hours=8))


def _budget_window(now: datetime | None = None) -> tuple[datetime, datetime]:
    current = now.astimezone(CHINA_TZ) if now is not None else datetime.now(CHINA_TZ)
    start_local = current.replace(hour=0, minute=0, second=0, microsecond=0)
    end_local = start_local + timedelta(days=1)
    return start_local.astimezone(timezone.utc), end_local.astimezone(timezone.utc)


def get_daily_ai_usage(db: Session) -> int:
    if settings.daily_ai_turn_limit <= 0:
        return 0
    window_start, window_end = _budget_window()
    total = db.scalar(
        select(func.coalesce(func.sum(AIBudgetEvent.cost_units), 0)).where(
            AIBudgetEvent.created_at >= window_start,
            AIBudgetEvent.created_at < window_end,
        )
    )
    return int(total or 0)


def get_daily_ai_remaining(db: Session) -> int:
    if settings.daily_ai_turn_limit <= 0:
        return 10**9
    return max(settings.daily_ai_turn_limit - get_daily_ai_usage(db), 0)


def consume_ai_budget(
    db: Session,
    *,
    scope: str,
    device_id: str,
    cost_units: int = 1,
) -> bool:
    if settings.daily_ai_turn_limit <= 0:
        return True
    if cost_units <= 0:
        return True
    if get_daily_ai_remaining(db) < cost_units:
        return False

    db.add(
        AIBudgetEvent(
            scope=scope,
            device_id=device_id,
            cost_units=cost_units,
        )
    )
    db.commit()
    return True
