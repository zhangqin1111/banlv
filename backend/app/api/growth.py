from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.growth import GrowthSummaryResponse
from app.services.growth_service import build_growth_summary

router = APIRouter(prefix="/growth", tags=["growth"])


@router.get("/summary", response_model=GrowthSummaryResponse)
def growth_summary(
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> GrowthSummaryResponse:
    return build_growth_summary(db, device_id=device_id)


@router.get("/events", response_model=GrowthSummaryResponse)
def growth_events(
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> GrowthSummaryResponse:
    return build_growth_summary(db, device_id=device_id)
