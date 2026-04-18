from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AIBudgetEvent(Base):
    __tablename__ = "ai_budget_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    scope: Mapped[str] = mapped_column(String(32), index=True)
    device_id: Mapped[str] = mapped_column(String(64), index=True)
    cost_units: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        index=True,
    )
