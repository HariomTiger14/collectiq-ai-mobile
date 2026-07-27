from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx

from app.core.config import settings


PRICECHARTING_SOURCE_FILES = (
    "magic.csv",
    "one_piece.csv",
    "pokemon.csv",
    "video_games.csv",
    "yugioh.csv",
)


class PriceChartingStatusError(Exception):
    """Raised when PriceCharting catalog status cannot be checked."""


@dataclass(frozen=True)
class PriceChartingStatusService:
    supabase_url: str | None = None
    service_role_key: str | None = None
    timeout_seconds: float = 10
    client: httpx.Client | None = None

    @property
    def is_configured(self) -> bool:
        return bool(self._supabase_url and self._service_role_key)

    def status(self) -> dict[str, Any]:
        if not self.is_configured:
            raise PriceChartingStatusError("Supabase catalog status is not configured.")

        sources = []
        total_current_rows = 0
        total_history_current_rows = 0
        total_history_inactive_rows = 0
        latest_loaded_at: str | None = None

        for source_file in PRICECHARTING_SOURCE_FILES:
            current_rows = self._count(
                "pricecharting_catalog",
                {"source_file": source_file},
            )
            history_current_rows = self._count(
                "pricecharting_catalog_history",
                {"source_file": source_file, "is_current": "true"},
            )
            history_inactive_rows = self._count(
                "pricecharting_catalog_history",
                {"source_file": source_file, "is_current": "false"},
            )
            first_loaded_at = self._timestamp(
                "pricecharting_catalog",
                source_file,
                ascending=True,
            )
            last_loaded_at = self._timestamp(
                "pricecharting_catalog",
                source_file,
                ascending=False,
            )

            total_current_rows += current_rows
            total_history_current_rows += history_current_rows
            total_history_inactive_rows += history_inactive_rows
            latest_loaded_at = _max_timestamp(latest_loaded_at, last_loaded_at)

            sources.append(
                {
                    "sourceFile": source_file,
                    "currentRows": current_rows,
                    "historyCurrentRows": history_current_rows,
                    "historyInactiveRows": history_inactive_rows,
                    "firstLoadedAt": first_loaded_at,
                    "lastLoadedAt": last_loaded_at,
                    "historyAligned": current_rows == history_current_rows,
                }
            )

        return {
            "success": True,
            "provider": "PriceCharting",
            "sourceCount": len(sources),
            "totalCurrentRows": total_current_rows,
            "totalHistoryCurrentRows": total_history_current_rows,
            "totalHistoryInactiveRows": total_history_inactive_rows,
            "totalHistoryRows": total_history_current_rows + total_history_inactive_rows,
            "latestLoadedAt": latest_loaded_at,
            "historyAligned": total_current_rows == total_history_current_rows,
            "sources": sources,
        }

    @property
    def _supabase_url(self) -> str:
        value = self.supabase_url if self.supabase_url is not None else settings.supabase_url
        return value.strip().rstrip("/")

    @property
    def _service_role_key(self) -> str:
        value = (
            self.service_role_key
            if self.service_role_key is not None
            else settings.supabase_service_role_key
        )
        return value.strip()

    def _count(self, table: str, filters: dict[str, str]) -> int:
        response = self._request(
            "GET",
            f"/rest/v1/{table}",
            params={
                "select": "id",
                "limit": "1",
                **{key: f"eq.{value}" for key, value in filters.items()},
            },
            headers={"Prefer": "count=exact"},
        )
        return _count_from_content_range(response.headers.get("content-range", ""))

    def _timestamp(self, table: str, source_file: str, *, ascending: bool) -> str | None:
        payload = self._json_request(
            "GET",
            f"/rest/v1/{table}",
            params={
                "select": "source_downloaded_at",
                "source_file": f"eq.{source_file}",
                "order": f"source_downloaded_at.{'asc' if ascending else 'desc'}.nullslast",
                "limit": "1",
            },
        )
        if not isinstance(payload, list) or not payload:
            return None
        value = payload[0].get("source_downloaded_at")
        return str(value) if value else None

    def _json_request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, str] | None = None,
    ) -> Any:
        response = self._request(method, path, params=params)
        if not response.content:
            return None
        try:
            return response.json()
        except ValueError as error:
            raise PriceChartingStatusError("PriceCharting status returned invalid JSON.") from error

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, str] | None = None,
        headers: dict[str, str] | None = None,
    ) -> httpx.Response:
        request_headers = {
            "apikey": self._service_role_key,
            "Authorization": f"Bearer {self._service_role_key}",
            "Accept": "application/json",
            "Content-Type": "application/json",
            **(headers or {}),
        }
        client = self.client or httpx.Client(timeout=self.timeout_seconds)
        should_close = self.client is None
        try:
            response = client.request(
                method,
                f"{self._supabase_url}{path}",
                headers=request_headers,
                params=params,
            )
            response.raise_for_status()
            return response
        except httpx.HTTPError as error:
            raise PriceChartingStatusError("PriceCharting status request failed.") from error
        finally:
            if should_close:
                client.close()


def _count_from_content_range(value: str) -> int:
    try:
        return int(value.rsplit("/", 1)[1])
    except (IndexError, ValueError):
        return 0


def _max_timestamp(current: str | None, candidate: str | None) -> str | None:
    if not current:
        return candidate
    if not candidate:
        return current
    return max(current, candidate)
