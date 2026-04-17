from pydantic import BaseModel


class TreeholeSessionCreateRequest(BaseModel):
    mood_entry_id: str | None = None
    opener: str | None = None


class TreeholeSessionCreateResponse(BaseModel):
    session_id: str
    status: str = "active"


class TreeholeStreamRequest(BaseModel):
    message: str
    companion_mode: str | None = None


class TreeholeReplyResponse(BaseModel):
    session_id: str
    message_id: str | None = None
    message: str = ""
    suggestion: str | None = None
    blocked: bool = False
    reason: str | None = None
    severity: str | None = None
    status: str = "ok"


class TreeholeFeedbackRequest(BaseModel):
    helpful_score: int


class TreeholeMessageItem(BaseModel):
    role: str
    content: str
    created_at: str


class TreeholeMessagesResponse(BaseModel):
    session_id: str
    items: list[TreeholeMessageItem]
