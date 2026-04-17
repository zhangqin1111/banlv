from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.blind_box_draw import BlindBoxDraw
from app.models.device import Device
from app.models.growth import GrowthEvent, GrowthProfile
from app.models.mode_session import ModeSession
from app.models.mood_entry import MoodEntry
from app.models.report import Report
from app.models.treehole import TreeholeMessage, TreeholeSession
from app.schemas.settings import DeleteAccountResponse


def delete_account_data(db: Session, *, device_id: str) -> DeleteAccountResponse:
    sessions = db.scalars(
        select(TreeholeSession).where(TreeholeSession.device_id == device_id)
    ).all()
    session_ids = [session.id for session in sessions]

    if session_ids:
        db.query(TreeholeMessage).filter(
            TreeholeMessage.session_id.in_(session_ids)
        ).delete(synchronize_session=False)

    db.query(TreeholeSession).filter(
        TreeholeSession.device_id == device_id
    ).delete(synchronize_session=False)
    db.query(ModeSession).filter(
        ModeSession.device_id == device_id
    ).delete(synchronize_session=False)
    db.query(MoodEntry).filter(
        MoodEntry.device_id == device_id
    ).delete(synchronize_session=False)
    db.query(BlindBoxDraw).filter(
        BlindBoxDraw.device_id == device_id
    ).delete(synchronize_session=False)
    db.query(GrowthEvent).filter(
        GrowthEvent.device_id == device_id
    ).delete(synchronize_session=False)
    db.query(GrowthProfile).filter(
        GrowthProfile.device_id == device_id
    ).delete(synchronize_session=False)
    db.query(Report).filter(Report.device_id == device_id).delete(
        synchronize_session=False
    )

    device = db.scalar(select(Device).where(Device.device_id == device_id))
    if device is not None:
        device.deleted_at = datetime.now(timezone.utc)

    db.commit()
    return DeleteAccountResponse(status="queued")
