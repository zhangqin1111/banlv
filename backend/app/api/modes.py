from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.modes import ModeSessionCreateRequest, ModeSessionCreateResponse
from app.services.mode_service import create_mode_session

router = APIRouter(prefix="/modes", tags=["modes"])


@router.post("/sessions", response_model=ModeSessionCreateResponse)
def create_session(
    payload: ModeSessionCreateRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> ModeSessionCreateResponse:
    return create_mode_session(db, device_id=device_id, payload=payload)
