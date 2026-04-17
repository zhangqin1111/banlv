from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.auth import GuestAuthResponse
from app.services.device_service import create_guest_device

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/guest", response_model=GuestAuthResponse)
def guest_auth(db: Session = Depends(get_db)) -> GuestAuthResponse:
    device_id, anon_token = create_guest_device(db)
    return GuestAuthResponse(device_id=device_id, anon_token=anon_token)
