from pydantic import BaseModel, Field


class GrowthEventItem(BaseModel):
    source_type: str
    delta_points: int
    created_at: str


class GrowthSummaryResponse(BaseModel):
    growth_points: int
    current_stage: str
    next_stage_at: int
    recent_events: list[GrowthEventItem] = Field(default_factory=list)
