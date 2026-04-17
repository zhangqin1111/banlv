from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.blind_box import (
    BlindBoxDrawRequest,
    BlindBoxDrawResponse,
    BlindBoxSaveResponse,
)
from app.services.blind_box_service import draw_card, save_draw

router = APIRouter(prefix="/blind-box", tags=["blind-box"])


@router.post("/draw", response_model=BlindBoxDrawResponse)
def draw_blind_box(
    payload: BlindBoxDrawRequest,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> BlindBoxDrawResponse:
    return draw_card(db, device_id=device_id, payload=payload)


@router.post("/{draw_id}/save", response_model=BlindBoxSaveResponse)
def save_blind_box(
    draw_id: str,
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> BlindBoxSaveResponse:
    saved = save_draw(db, device_id=device_id, draw_id=draw_id)
    if not saved:
        raise HTTPException(status_code=404, detail="Draw not found.")
    return BlindBoxSaveResponse(draw_id=draw_id, is_saved=True)
