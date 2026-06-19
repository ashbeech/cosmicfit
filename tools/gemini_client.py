#!/usr/bin/env python3
"""
Cosmic Fit — shared Google GenAI client (google.genai SDK).

Used by content_audit_apply.py and backfill_narratives.py.
"""

from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent

DEFAULT_MODEL = "gemini-3.1-pro-preview"
FALLBACK_MODELS = [
    "gemini-3.1-pro-preview",
    "gemini-2.5-flash",
    "gemini-3.5-flash",
    "gemini-flash-latest",
]

MAX_RETRIES = 3
RETRY_BACKOFF = [2, 4, 8]
MAX_429_WAIT_SEC = 300
MAX_RATE_LIMIT_WAITS = 10
RATE_LIMIT_BUFFER_SEC = 5
DEFAULT_REQUEST_TIMEOUT = 240


class QuotaExhaustedError(Exception):
    """Raised when Gemini API quota is exhausted."""


def load_local_env_file() -> None:
    """Load .env keys into os.environ if not already set."""
    candidate_paths = [
        Path.cwd() / ".env",
        Path(__file__).resolve().parent / ".env",
        REPO_ROOT / ".env",
    ]
    seen: set[Path] = set()
    for env_path in candidate_paths:
        if env_path in seen or not env_path.exists():
            continue
        seen.add(env_path)
        for raw_line in env_path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip("'\"")
            if key and key not in os.environ:
                os.environ[key] = value


def resolve_api_keys(cli_value: str | None) -> list[str]:
    if cli_value:
        return [cli_value]
    keys: list[str] = []
    for i in range(1, 100):
        val = os.environ.get(f"GEMINI_API_KEY_{i}", "").strip()
        if not val:
            break
        keys.append(val)
    if keys:
        return keys
    legacy = os.environ.get("GEMINI_API_KEY", "").strip()
    if legacy:
        return [legacy]
    return []


def resolve_model_name(cli_value: str | None) -> str:
    if cli_value:
        return cli_value.strip()
    env_value = os.environ.get("GEMINI_MODEL", "").strip()
    if env_value:
        return env_value
    return DEFAULT_MODEL


def resolve_request_timeout() -> float:
    raw = os.environ.get("GEMINI_REQUEST_TIMEOUT", "").strip()
    if not raw:
        return float(DEFAULT_REQUEST_TIMEOUT)
    try:
        value = float(raw)
    except ValueError:
        return float(DEFAULT_REQUEST_TIMEOUT)
    return max(30.0, min(value, 600.0))


def _is_rate_limited(err: Exception) -> bool:
    msg = str(err)
    return "429" in msg or "RESOURCE_EXHAUSTED" in msg


def _is_timeout(err: Exception) -> bool:
    if isinstance(err, TimeoutError):
        return True
    msg = str(err).lower()
    return "timeout" in msg or "timed out" in msg


def _is_model_not_found(err: Exception) -> bool:
    msg = str(err)
    return "404" in msg and ("NOT_FOUND" in msg or "no longer available" in msg)


def _parse_retry_delay(err: Exception) -> int:
    msg = str(err)
    match = re.search(r"retryDelay.*?(\d+)s", msg)
    if match:
        return int(match.group(1))
    match = re.search(r"retry_delay\s*\{[^}]*seconds:\s*(\d+)", msg)
    if match:
        return int(match.group(1))
    return 0


class GeminiClient:
    """Thin wrapper around google.genai for text and JSON generation."""

    def __init__(self, api_key: str, model_name: str | None = None):
        from google import genai
        from google.genai import types

        self._genai = genai
        self._api_key = api_key
        self._model = resolve_model_name(model_name)
        self._timeout = resolve_request_timeout()
        timeout_ms = int(self._timeout * 1000)
        self._client = genai.Client(
            api_key=api_key,
            http_options=types.HttpOptions(timeout=timeout_ms),
        )

    @property
    def model(self) -> str:
        return self._model

    def _fallback_model(self) -> str | None:
        for candidate in FALLBACK_MODELS:
            if candidate != self._model:
                return candidate
        return None

    def generate_text(
        self,
        user_prompt: str,
        system_instruction: str | None = None,
    ) -> str:
        """Generate plain text. Raises on persistent failure."""
        from google.genai import types

        config_kwargs: dict[str, Any] = {}
        if system_instruction:
            config_kwargs["system_instruction"] = system_instruction

        return self._generate_with_retries(
            user_prompt,
            types.GenerateContentConfig(**config_kwargs),
        )

    def generate_json(
        self,
        user_prompt: str,
        system_instruction: str,
        response_json_schema: dict,
    ) -> dict[str, Any]:
        """Generate structured JSON matching response_json_schema."""
        from google.genai import types

        config = types.GenerateContentConfig(
            system_instruction=system_instruction,
            response_mime_type="application/json",
            response_json_schema=response_json_schema,
        )
        text = self._generate_with_retries(user_prompt, config)
        return json.loads(text)

    def _generate_with_retries(self, user_prompt: str, config: Any) -> str:
        rate_limit_waits = 0
        attempt = 0
        last_error: Exception | None = None

        while attempt < MAX_RETRIES:
            attempt += 1
            try:
                response = self._client.models.generate_content(
                    model=self._model,
                    contents=user_prompt,
                    config=config,
                )
                text = (response.text or "").strip()
                if not text:
                    raise ValueError("empty response text from Gemini")
                return text

            except Exception as e:
                last_error = e

                if _is_model_not_found(e):
                    fallback = self._fallback_model()
                    if fallback:
                        print(f"    Model {self._model} unavailable, falling back to {fallback}")
                        self._model = fallback
                        attempt -= 1
                        continue
                    raise RuntimeError(
                        f"Gemini model {self._model} not found and no fallback available. "
                        f"Set GEMINI_MODEL to one of: {', '.join(FALLBACK_MODELS)}"
                    ) from e

                if _is_rate_limited(e):
                    retry_sec = _parse_retry_delay(e)
                    if (
                        retry_sec > 0
                        and retry_sec <= MAX_429_WAIT_SEC
                        and rate_limit_waits < MAX_RATE_LIMIT_WAITS
                    ):
                        wait_sec = retry_sec + RATE_LIMIT_BUFFER_SEC
                        rate_limit_waits += 1
                        attempt -= 1
                        print(
                            f"    Rate limited — waiting {wait_sec}s "
                            f"({rate_limit_waits}/{MAX_RATE_LIMIT_WAITS})..."
                        )
                        time.sleep(wait_sec)
                        continue
                    raise QuotaExhaustedError(str(e)) from e

                if _is_timeout(e) and attempt < MAX_RETRIES:
                    print(f"    Request timed out after {self._timeout}s — retrying...")
                    continue

                if attempt < MAX_RETRIES:
                    time.sleep(RETRY_BACKOFF[attempt - 1])
                    continue

        raise RuntimeError(
            f"Gemini API failed after {MAX_RETRIES} attempts (model={self._model}): {last_error}"
        ) from last_error


REWRITE_JSON_SCHEMA = {
    "type": "object",
    "properties": {
        "rewrites": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "json_edit_path": {"type": "string"},
                    "new_value": {"type": "string"},
                },
                "required": ["json_edit_path", "new_value"],
            },
        },
    },
    "required": ["rewrites"],
}
