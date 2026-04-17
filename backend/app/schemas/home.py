from pydantic import BaseModel, Field


class HomeDuoLineResponse(BaseModel):
    speaker: str = "momo"
    text: str = "今天先慢一点。"
    mood: str = "soft_smile"


class HomeSummaryResponse(BaseModel):
    momo_stage: str = "bloom"
    growth_points: int = 18
    last_summary: str = "今天想从哪里开始都可以。"
    entry_badges: list[str] = Field(
        default_factory=lambda: ["treehole", "mood_weather", "blind_box", "growth"]
    )
    whisper_lines: list[str] = Field(
        default_factory=lambda: [
            "今天的你辛苦了。",
            "黑夜再长，也会有一点星光。",
            "如果想先安静一下，我就在这里。",
        ]
    )
    duo_chat_lines: list[HomeDuoLineResponse] = Field(
        default_factory=lambda: [
            HomeDuoLineResponse(
                speaker="momo",
                text="今天先把肩膀放松一点吧。",
                mood="soft_smile",
            ),
            HomeDuoLineResponse(
                speaker="lulu",
                text="嗯，我们陪你慢慢把这口气放下来。",
                mood="cheer",
            ),
            HomeDuoLineResponse(
                speaker="momo",
                text="如果只想待一会，也已经很好了。",
                mood="happy",
            ),
            HomeDuoLineResponse(
                speaker="lulu",
                text="那我就把小岛再暖一点，等你靠过来。",
                mood="curious",
            ),
        ]
    )
    duo_chat_turn_limit: int = 4
