from pydantic import BaseModel


class ReportCreateRequest(BaseModel):
    source_type: str
    source_id: str
    category: str
    message: str = ""


class ReportCreateResponse(BaseModel):
    report_id: str
    status: str = "received"
