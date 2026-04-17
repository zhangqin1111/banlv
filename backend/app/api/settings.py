from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_device_id
from app.db.session import get_db
from app.schemas.settings import DeleteAccountResponse
from app.services.settings_service import delete_account_data

router = APIRouter(prefix="/settings", tags=["settings"])


@router.post("/delete-account", response_model=DeleteAccountResponse)
def delete_account(
    device_id: str = Depends(get_current_device_id),
    db: Session = Depends(get_db),
) -> DeleteAccountResponse:
    return delete_account_data(db, device_id=device_id)
