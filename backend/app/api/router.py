from fastapi import APIRouter

from app.api import (
    auth,
    blind_box,
    growth,
    home,
    modes,
    mood_weather,
    records,
    report,
    settings,
    treehole,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(home.router)
api_router.include_router(mood_weather.router)
api_router.include_router(treehole.router)
api_router.include_router(modes.router)
api_router.include_router(blind_box.router)
api_router.include_router(growth.router)
api_router.include_router(records.router)
api_router.include_router(report.router)
api_router.include_router(settings.router)
