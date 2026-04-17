import os
from dataclasses import dataclass
from functools import lru_cache


@dataclass(frozen=True)
class Settings:
    app_name: str = "EmoBot API"
    app_env: str = "local"
    debug: bool = True
    host: str = "0.0.0.0"
    port: int = 8000
    database_url: str = (
        "postgresql+psycopg://postgres:postgres@localhost:5432/emobot"
    )
    qwen_api_key: str = ""
    qwen_base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    qwen_model: str = "qwen-plus"


@lru_cache
def get_settings() -> Settings:
    return Settings(
        app_env=os.getenv("APP_ENV", "local"),
        debug=os.getenv("APP_DEBUG", "true").lower() == "true",
        host=os.getenv("APP_HOST", "0.0.0.0"),
        port=int(os.getenv("APP_PORT", "8000")),
        database_url=os.getenv(
            "DATABASE_URL",
            "postgresql+psycopg://postgres:postgres@localhost:5432/emobot",
        ),
        qwen_api_key=os.getenv("QWEN_API_KEY", ""),
        qwen_base_url=os.getenv(
            "QWEN_BASE_URL",
            "https://dashscope.aliyuncs.com/compatible-mode/v1",
        ),
        qwen_model=os.getenv("QWEN_MODEL", "qwen-plus"),
    )
