import unittest
from unittest.mock import patch

import httpx
from fastapi.testclient import TestClient

from app.main import app
from app.services.pricing.pricecharting_status_service import PriceChartingStatusService


class PriceChartingStatusServiceTest(unittest.TestCase):
    def test_status_summarizes_current_and_history_rows(self) -> None:
        service = PriceChartingStatusService(
            supabase_url="https://example.supabase.co",
            service_role_key="service-role",
            client=_FakeSupabaseStatusClient(),
        )

        status = service.status()

        self.assertTrue(status["success"])
        self.assertEqual(status["provider"], "PriceCharting")
        self.assertEqual(status["sourceCount"], 5)
        self.assertEqual(status["totalCurrentRows"], 432344)
        self.assertEqual(status["totalHistoryCurrentRows"], 432344)
        self.assertEqual(status["totalHistoryInactiveRows"], 17148)
        self.assertEqual(status["totalHistoryRows"], 449492)
        self.assertTrue(status["historyAligned"])
        self.assertEqual(status["latestLoadedAt"], "2026-07-26T14:30:17.1166+00:00")
        pokemon = next(row for row in status["sources"] if row["sourceFile"] == "pokemon.csv")
        self.assertEqual(pokemon["currentRows"], 91278)
        self.assertEqual(pokemon["historyInactiveRows"], 5146)
        self.assertTrue(pokemon["historyAligned"])


class PriceChartingStatusEndpointTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_status_requires_admin_token(self) -> None:
        with patch("app.routers.admin_pricecharting.settings") as settings:
            settings.admin_job_token = "secret"

            response = self.client.get("/admin/pricecharting/status")

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["error"]["code"], "admin_token_required")

    def test_status_endpoint_returns_service_payload(self) -> None:
        with patch("app.routers.admin_pricecharting.settings") as settings, patch(
            "app.routers.admin_pricecharting.PriceChartingStatusService"
        ) as service_class:
            settings.admin_job_token = "secret"
            service_class.return_value.status.return_value = {
                "success": True,
                "provider": "PriceCharting",
                "totalCurrentRows": 432344,
            }

            response = self.client.get(
                "/admin/pricecharting/status",
                headers={"X-Admin-Token": "secret"},
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["totalCurrentRows"], 432344)


class _FakeSupabaseStatusClient:
    current_rows = {
        "magic.csv": 129605,
        "one_piece.csv": 11847,
        "pokemon.csv": 91278,
        "video_games.csv": 122186,
        "yugioh.csv": 77428,
    }
    inactive_rows = {
        "magic.csv": 4862,
        "one_piece.csv": 619,
        "pokemon.csv": 5146,
        "video_games.csv": 3761,
        "yugioh.csv": 2760,
    }

    def request(self, method: str, url: str, **kwargs) -> httpx.Response:
        params = kwargs.get("params") or {}
        source_file = str(params.get("source_file") or "").replace("eq.", "")
        request = httpx.Request(method, url)
        if "limit" in params and params.get("select") == "id":
            count = self._count_for(url, params, source_file)
            return httpx.Response(
                200,
                json=[],
                headers={"content-range": f"0-0/{count}"},
                request=request,
            )
        if params.get("select") == "source_downloaded_at":
            return httpx.Response(
                200,
                json=[{"source_downloaded_at": "2026-07-26T14:30:17.1166+00:00"}],
                request=request,
            )
        return httpx.Response(404, json={"error": "unexpected request"}, request=request)

    def _count_for(self, url: str, params: dict, source_file: str) -> int:
        if url.endswith("/pricecharting_catalog"):
            return self.current_rows[source_file]
        if url.endswith("/pricecharting_catalog_history"):
            is_current = params.get("is_current") == "eq.true"
            if is_current:
                return self.current_rows[source_file]
            return self.inactive_rows[source_file]
        return 0


if __name__ == "__main__":
    unittest.main()
