from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.home import HomeSummaryResponse
from app.services.home_service import get_home_summary

router = APIRouter(prefix="/home", tags=["home"])


@router.get("/summary", response_model=HomeSummaryResponse)
def home_summary(
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> HomeSummaryResponse:
    return get_home_summary(db, device_id=device_id)
