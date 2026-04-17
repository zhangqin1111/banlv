from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.device_service import ensure_device_exists


def get_current_device_id(
    x_device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> str:
    if not x_device_id:
        raise HTTPException(status_code=401, detail="Missing X-Device-Id header.")

    ensure_device_exists(db, x_device_id)
    return x_device_id
