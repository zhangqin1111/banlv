from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import get_settings
from app.db.base import Base
from app.db.session import engine
from app.models import (  # noqa: F401
    AgentProfile,
    BlindBoxDraw,
    CrisisEvent,
    Device,
    GrowthEvent,
    GrowthProfile,
    HomeWhisper,
    ModeSession,
    MoodEntry,
    Report,
    TreeholeMessage,
    TreeholeSession,
)

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    debug=settings.debug,
    summary="EmoBot original-demand-compatible MVP backend.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "env": settings.app_env}


app.include_router(api_router, prefix="/v1")
