import json
from collections.abc import AsyncIterator

import httpx

from app.core.config import get_settings

settings = get_settings()


class QwenClient:
    """DashScope OpenAI-compatible streaming client."""

    def __init__(self) -> None:
        self.base_url = settings.qwen_base_url
        self.model = settings.qwen_model
        self.api_key = settings.qwen_api_key

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key)

    def auth_headers(self) -> dict[str, str]:
        if not self.api_key:
            return {}
        return {"Authorization": f"Bearer {self.api_key}"}

    def _request_payload(
        self,
        *,
        messages: list[dict[str, str]],
        temperature: float,
        max_tokens: int,
        stream: bool,
    ) -> dict[str, object]:
        payload: dict[str, object] = {
            "model": self.model,
            "messages": messages,
            "stream": stream,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if stream:
            payload["stream_options"] = {"include_usage": True}
        return payload

    def _extract_message(self, parsed: dict[str, object]) -> str:
        choices = parsed.get("choices") or []
        if not isinstance(choices, list) or not choices:
            return ""
        message = choices[0].get("message") or {}
        if not isinstance(message, dict):
            return ""
        content = message.get("content")
        return content if isinstance(content, str) else ""

    async def stream_chat(
        self,
        *,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 240,
    ) -> AsyncIterator[str]:
        if not self.is_configured:
            raise RuntimeError("Qwen API key is not configured.")

        url = f"{self.base_url.rstrip('/')}/chat/completions"
        headers = {
            **self.auth_headers(),
            "Content-Type": "application/json",
        }
        payload = self._request_payload(
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True,
        )

        async with httpx.AsyncClient(timeout=None) as client:
            async with client.stream(
                "POST",
                url,
                headers=headers,
                json=payload,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if not line.startswith("data:"):
                        continue

                    chunk = line[5:].strip()
                    if not chunk or chunk == "[DONE]":
                        continue

                    parsed = json.loads(chunk)
                    choices = parsed.get("choices") or []
                    if not choices:
                        continue

                    delta = choices[0].get("delta") or {}
                    content = delta.get("content")
                    if isinstance(content, str) and content:
                        yield content

    async def complete_chat_async(
        self,
        *,
        messages: list[dict[str, str]],
        temperature: float = 0.5,
        max_tokens: int = 220,
    ) -> str:
        if not self.is_configured:
            raise RuntimeError("Qwen API key is not configured.")

        url = f"{self.base_url.rstrip('/')}/chat/completions"
        headers = {
            **self.auth_headers(),
            "Content-Type": "application/json",
        }
        payload = self._request_payload(
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=False,
        )

        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            return self._extract_message(response.json()).strip()

    def complete_chat(
        self,
        *,
        messages: list[dict[str, str]],
        temperature: float = 0.5,
        max_tokens: int = 220,
    ) -> str:
        if not self.is_configured:
            raise RuntimeError("Qwen API key is not configured.")

        url = f"{self.base_url.rstrip('/')}/chat/completions"
        headers = {
            **self.auth_headers(),
            "Content-Type": "application/json",
        }
        payload = self._request_payload(
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=False,
        )

        with httpx.Client(timeout=45.0) as client:
            response = client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            return self._extract_message(response.json()).strip()
