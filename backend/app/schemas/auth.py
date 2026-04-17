from pydantic import BaseModel


class GuestAuthResponse(BaseModel):
    device_id: str
    anon_token: str
