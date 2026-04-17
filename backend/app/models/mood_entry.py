from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class MoodEntry(Base):
    __tablename__ = "mood_entries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    device_id: Mapped[str] = mapped_column(String(64), index=True)
    emotion: Mapped[str] = mapped_column(String(32))
    intensity: Mapped[int] = mapped_column(Integer)
    note_text: Mapped[str] = mapped_column(Text, default="")
    recommended_mode: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
