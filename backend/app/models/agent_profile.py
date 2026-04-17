from datetime import datetime, timezone

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AgentProfile(Base):
    __tablename__ = "agent_profiles"

    device_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    bond_score: Mapped[int] = mapped_column(Integer, default=0)
    turn_count: Mapped[int] = mapped_column(Integer, default=0)
    helpful_turn_count: Mapped[int] = mapped_column(Integer, default=0)
    support_preference: Mapped[str] = mapped_column(String(24), default="listen")
    last_strategy: Mapped[str] = mapped_column(String(24), default="listen")
    last_intent: Mapped[str] = mapped_column(String(24), default="share")
    last_emotion: Mapped[str] = mapped_column(String(24), default="neutral")
    last_mode_suggestion: Mapped[str | None] = mapped_column(String(24), nullable=True)
    memory_summary: Mapped[str] = mapped_column(Text, default="")
    topic_summary: Mapped[str] = mapped_column(Text, default="")
    preference_summary: Mapped[str] = mapped_column(Text, default="")
    helpful_summary: Mapped[str] = mapped_column(Text, default="")
    relationship_note: Mapped[str] = mapped_column(Text, default="")
    reflection_note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
