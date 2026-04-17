from pydantic import BaseModel, Field


class MoodWeatherCheckinRequest(BaseModel):
    emotion: str
    intensity: int
    note_text: str = ""


class InviteCard(BaseModel):
    type: str
    title: str
    route: str
    mode: str | None = None


class MoodWeatherCheckinResponse(BaseModel):
    checkin_id: str
    empathy_text: str
    recommended_mode: str
    invite_cards: list[InviteCard] = Field(default_factory=list)
