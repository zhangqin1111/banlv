from pydantic import BaseModel


class ModeSessionCreateRequest(BaseModel):
    mood_entry_id: str | None = None
    mode_type: str
    duration_sec: int
    helpful_score: int = 2


class ModeSessionCreateResponse(BaseModel):
    session_id: str
    mode_type: str
    awarded_points: int
    result_summary: str
