from pydantic import BaseModel


class BlindBoxDrawRequest(BaseModel):
    mood_entry_id: str | None = None
    worry_text: str = ""


class BlindBoxDrawResponse(BaseModel):
    draw_id: str
    card_type: str
    card_title: str
    card_body: str


class BlindBoxSaveResponse(BaseModel):
    draw_id: str
    is_saved: bool
