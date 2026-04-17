from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.report import Report
from app.schemas.report import ReportCreateRequest, ReportCreateResponse


def create_report(
    db: Session,
    *,
    device_id: str,
    payload: ReportCreateRequest,
) -> ReportCreateResponse:
    report = Report(
        device_id=device_id,
        source_type=payload.source_type,
        source_id=payload.source_id,
        category=payload.category,
        message=payload.message,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return ReportCreateResponse(report_id=report.id or str(uuid4()))
