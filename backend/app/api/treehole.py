from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.common import StatusResponse
from app.schemas.treehole import (
    TreeholeFeedbackRequest,
    TreeholeMessagesResponse,
    TreeholeReplyResponse,
    TreeholeSessionCreateRequest,
    TreeholeSessionCreateResponse,
    TreeholeStreamRequest,
)
from app.services.treehole_service import (
    create_session,
    get_messages,
    reply_once,
    save_feedback,
    stream_reply,
)

router = APIRouter(prefix="/treehole", tags=["treehole"])


@router.post("/sessions", response_model=TreeholeSessionCreateResponse)
def create_treehole_session(
    payload: TreeholeSessionCreateRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> TreeholeSessionCreateResponse:
    return create_session(db, device_id=device_id, payload=payload)


@router.post("/sessions/{session_id}/reply", response_model=TreeholeReplyResponse)
async def reply_treehole_once(
    session_id: str,
    payload: TreeholeStreamRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> TreeholeReplyResponse:
    return await reply_once(
        db,
        device_id=device_id,
        session_id=session_id,
        message=payload.message,
        companion_mode=payload.companion_mode,
    )


@router.post("/sessions/{session_id}/stream")
def stream_treehole_reply(
    session_id: str,
    payload: TreeholeStreamRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> StreamingResponse:
    return StreamingResponse(
        stream_reply(
            db,
            device_id=device_id,
            session_id=session_id,
            message=payload.message,
            companion_mode=payload.companion_mode,
        ),
        media_type="text/event-stream",
    )


@router.post("/sessions/{session_id}/feedback", response_model=StatusResponse)
def treehole_feedback(
    session_id: str,
    payload: TreeholeFeedbackRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> StatusResponse:
    return save_feedback(
        db,
        device_id=device_id,
        session_id=session_id,
        payload=payload,
    )


@router.get("/sessions/{session_id}/messages", response_model=TreeholeMessagesResponse)
def treehole_messages(
    session_id: str,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> TreeholeMessagesResponse:
    return get_messages(db, device_id=device_id, session_id=session_id)
