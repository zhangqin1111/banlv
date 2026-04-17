import hashlib
from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.device import Device
from app.models.growth import GrowthProfile


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_guest_device(db: Session) -> tuple[str, str]:
    device_id = str(uuid4())
    anon_token = f"guest_{uuid4().hex}"
    device = Device(
        device_id=device_id,
        anon_token_hash=_hash_token(anon_token),
    )
    db.add(device)
    db.add(GrowthProfile(device_id=device_id, growth_points=0, current_stage="seed"))
    db.commit()
    return device_id, anon_token


def ensure_device_exists(db: Session, device_id: str) -> Device:
    existing = db.scalar(select(Device).where(Device.device_id == device_id))
    if existing is not None:
        existing.last_active_at = datetime.now(timezone.utc)
        if existing.deleted_at is not None:
            existing.deleted_at = None
        db.commit()
        db.refresh(existing)
        return existing

    fallback_token = f"restored_{uuid4().hex}"
    device = Device(
        device_id=device_id,
        anon_token_hash=_hash_token(fallback_token),
    )
    db.add(device)
    db.add(GrowthProfile(device_id=device_id, growth_points=0, current_stage="seed"))
    db.commit()
    db.refresh(device)
    return device
