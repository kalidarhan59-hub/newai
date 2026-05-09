"""Application configuration loaded from environment variables."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for the backend.

    Values are loaded from environment variables and a ``.env`` file in the
    backend directory. Every secret is optional — if missing, the matching
    provider falls back to a deterministic mock implementation.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # Server ----------------------------------------------------------------
    host: str = "0.0.0.0"
    port: int = 8000
    log_level: str = "INFO"
    cors_origins: str = "http://localhost:3000,http://127.0.0.1:3000"

    # Storage ---------------------------------------------------------------
    data_dir: Path = Field(default=Path("./data"))

    # AI providers ----------------------------------------------------------
    anthropic_api_key: str | None = None
    openai_api_key: str | None = None
    google_api_key: str | None = None
    deepseek_api_key: str | None = None

    # Tools -----------------------------------------------------------------
    tavily_api_key: str | None = None
    serper_api_key: str | None = None
    elevenlabs_api_key: str | None = None

    # Derived ---------------------------------------------------------------
    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def chroma_dir(self) -> Path:
        return self.data_dir / "chroma"

    @property
    def upload_dir(self) -> Path:
        return self.data_dir / "uploads"

    def ensure_dirs(self) -> None:
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.chroma_dir.mkdir(parents=True, exist_ok=True)
        self.upload_dir.mkdir(parents=True, exist_ok=True)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    settings = Settings()
    settings.ensure_dirs()
    return settings
