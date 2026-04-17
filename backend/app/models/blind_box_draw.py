from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class BlindBoxDraw(Base):
    __tablename__ = "blind_box_draws"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    device_id: Mapped[str] = mapped_column(String(64), index=True)
    mood_entry_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    worry_text_redacted: Mapped[str] = mapped_column(Text, default="")
    card_type: Mapped[str] = mapped_column(String(24))
    card_title: Mapped[str] = mapped_column(String(128))
    card_body: Mapped[str] = mapped_column(Text)
    is_saved: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
