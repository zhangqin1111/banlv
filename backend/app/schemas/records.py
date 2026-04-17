from pydantic import BaseModel, Field


class RecordItem(BaseModel):
    id: str
    source_type: str
    title: str
    subtitle: str
    created_at: str


class RecordsResponse(BaseModel):
    items: list[RecordItem] = Field(default_factory=list)
