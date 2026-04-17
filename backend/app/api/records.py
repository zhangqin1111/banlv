from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.common import StatusResponse
from app.schemas.records import RecordsResponse
from app.services.record_service import list_records

router = APIRouter(prefix="/records", tags=["records"])


@router.get("", response_model=RecordsResponse)
def records(
    days: int = 7,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> RecordsResponse:
    return list_records(db, device_id=device_id, days=days)


@router.delete("/{record_id}", response_model=StatusResponse)
def delete_record(record_id: str) -> StatusResponse:
    del record_id
    return StatusResponse(status="deleted")
