from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.mood_weather import (
    MoodWeatherCheckinRequest,
    MoodWeatherCheckinResponse,
)
from app.services.mood_weather_service import submit_checkin

router = APIRouter(prefix="/mood-weather", tags=["mood-weather"])


@router.post("/checkins", response_model=MoodWeatherCheckinResponse)
def create_checkin(
    payload: MoodWeatherCheckinRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> MoodWeatherCheckinResponse:
    return submit_checkin(db, device_id=device_id, payload=payload)
