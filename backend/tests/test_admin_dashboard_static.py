import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
WEB_ROOT = PROJECT_ROOT / "web"


class AdminDashboardStaticTest(unittest.TestCase):
    def test_root_dashboard_has_live_data_targets(self) -> None:
        html = (WEB_ROOT / "admin" / "index.html").read_text(encoding="utf-8")

        self.assertIn("PackLox Administration", html)
        self.assertIn('data-service-status="api"', html)
        self.assertIn('data-service-status="supabase"', html)
        self.assertIn('data-service-status="analyzer"', html)
        self.assertIn('data-service-status="cloudflare"', html)
        self.assertIn('data-env-field="commit"', html)
        self.assertIn('data-admin-token', html)
        self.assertIn('data-pricing-health-status', html)
        self.assertIn('data-pricecharting-form', html)
        self.assertIn('data-catalog-search-form', html)
        self.assertIn('data-pricing-quote-form', html)
        self.assertIn('data-action="ops-summary"', html)
        self.assertIn('data-validation-output', html)
        self.assertIn('config.js', html)
        self.assertIn('dashboard.js', html)

    def test_password_reset_route_is_preserved(self) -> None:
        self.assertTrue((WEB_ROOT / "auth" / "reset-password" / "index.html").exists())

    def test_admin_route_entry_exists_for_cloudflare_output(self) -> None:
        admin_index = WEB_ROOT / "admin" / "index.html"

        self.assertTrue(admin_index.exists())
        self.assertIn("PackLox Administration", admin_index.read_text(encoding="utf-8"))

    def test_dashboard_script_handles_healthy_offline_and_partial_states(self) -> None:
        script = (WEB_ROOT / "admin" / "dashboard.js").read_text(encoding="utf-8")

        self.assertIn("async getHealth()", script)
        self.assertIn("renderHealth", script)
        self.assertIn("renderOffline", script)
        self.assertIn('"Offline"', script)
        self.assertIn('"Unavailable"', script)
        self.assertIn("services.supabase ? \"Healthy\" : \"Offline\"", script)
        self.assertIn("services.analyzer ? \"Healthy\" : \"Unavailable\"", script)
        self.assertIn("window.setInterval(() => refreshHealth(client), config.refreshIntervalMs)", script)

    def test_dashboard_wires_existing_admin_backend_actions(self) -> None:
        script = (WEB_ROOT / "admin" / "dashboard.js").read_text(encoding="utf-8")

        self.assertIn("/admin/pricing/health", script)
        self.assertIn("/admin/ops/summary", script)
        self.assertIn("/admin/pricecharting/import", script)
        self.assertIn("/api/pricing/catalog/search", script)
        self.assertIn("/api/pricing/quote", script)
        self.assertIn('"X-Admin-Token"', script)
        self.assertIn("packlox-admin-token", script)
        self.assertIn("renderOpsSummary", script)

    def test_dashboard_config_points_to_sit_backend(self) -> None:
        config = (WEB_ROOT / "admin" / "config.js").read_text(encoding="utf-8")

        self.assertIn("https://api-sit.packlox.com", config)
        self.assertIn("https://sit.packlox.com", config)
        self.assertIn("refreshIntervalMs: 30000", config)


if __name__ == "__main__":
    unittest.main()
