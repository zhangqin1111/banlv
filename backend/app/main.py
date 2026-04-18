from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect, text

from app.api.router import api_router
from app.core.config import get_settings
from app.db.base import Base
from app.db.session import engine
from app.models import (  # noqa: F401
    AIBudgetEvent,
    AgentProfile,
    BlindBoxDraw,
    CrisisEvent,
    Device,
    GrowthEvent,
    GrowthProfile,
    HomeDuoChat,
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


def _ensure_runtime_schema() -> None:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    if "agent_profiles" not in existing_tables:
        return

    agent_profile_columns = {
        column["name"] for column in inspector.get_columns("agent_profiles")
    }

    with engine.begin() as connection:
        if "avoid_strategy" not in agent_profile_columns:
            connection.execute(
                text(
                    "ALTER TABLE agent_profiles "
                    "ADD COLUMN avoid_strategy VARCHAR(24)"
                )
            )


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)
    _ensure_runtime_schema()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "env": settings.app_env}


app.include_router(api_router, prefix="/v1")
