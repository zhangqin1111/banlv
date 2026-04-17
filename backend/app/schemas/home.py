from pydantic import BaseModel, Field


class HomeSummaryResponse(BaseModel):
    momo_stage: str = "bloom"
    growth_points: int = 18
    last_summary: str = "今天想从哪里开始都可以。"
    entry_badges: list[str] = Field(
        default_factory=lambda: ["treehole", "mood_weather", "blind_box", "growth"]
    )
    whisper_lines: list[str] = Field(
        default_factory=lambda: [
            "我先在这里陪你一会。",
            "不用马上整理好，我们慢一点也可以。",
            "今天想从哪一块开始，都算在往前。",
        ]
    )
