from pydantic import BaseModel


class DeleteAccountResponse(BaseModel):
    status: str = "queued"
