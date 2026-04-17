from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.report import ReportCreateRequest, ReportCreateResponse
from app.services.report_service import create_report

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("", response_model=ReportCreateResponse)
def report_issue(
    payload: ReportCreateRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> ReportCreateResponse:
    return create_report(db, device_id=device_id, payload=payload)
