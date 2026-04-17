from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ModeSession(Base):
    __tablename__ = "mode_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    device_id: Mapped[str] = mapped_column(String(64), index=True)
    mood_entry_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    mode_type: Mapped[str] = mapped_column(String(24))
    duration_sec: Mapped[int] = mapped_column(Integer)
    result_summary: Mapped[str] = mapped_column(Text, default="")
    helpful_score: Mapped[int | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
