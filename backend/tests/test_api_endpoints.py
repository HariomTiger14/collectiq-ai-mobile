import unittest

from fastapi.testclient import TestClient

from app.main import app


class ApiEndpointsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_health(self) -> None:
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_scanner_analyze_happy_path(self) -> None:
        response = self.client.post(
            "/scanner/analyze",
            files={"image": ("card.png", b"image-bytes", "image/png")},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertTrue(payload["filename"].endswith(".png"))
        self.assertIn("/uploads/", payload["imageUrl"])
        self.assertTrue(payload["title"])
        self.assertIn(
            payload["category"],
            {"Trading Card", "Sports Card", "Coin", "Comic", "Toy/Figure"},
        )
        self.assertGreaterEqual(payload["confidence"], 80)
        self.assertGreater(payload["estimatedValue"], 0)
        self.assertTrue(payload["condition"])
        self.assertTrue(payload["recommendation"])

    def test_scanner_analyze_invalid_extension(self) -> None:
        response = self.client.post(
            "/scanner/analyze",
            files={"image": ("card.gif", b"image-bytes", "image/gif")},
        )

        self.assertEqual(response.status_code, 415)
        self.assertFalse(response.json()["success"])

    def test_scanner_analyze_oversized_image(self) -> None:
        response = self.client.post(
            "/scanner/analyze",
            files={
                "image": (
                    "large.png",
                    b"0" * (10 * 1024 * 1024 + 1),
                    "image/png",
                )
            },
        )

        self.assertEqual(response.status_code, 413)
        self.assertFalse(response.json()["success"])

    def test_get_portfolio(self) -> None:
        response = self.client.get("/portfolio")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["success"])
        self.assertIsInstance(response.json()["items"], list)

    def test_post_portfolio(self) -> None:
        response = self.client.post(
            "/portfolio",
            json={"id": "test-item", "data": {"title": "Test Card"}},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertEqual(payload["item"]["id"], "test-item")
        self.assertEqual(payload["item"]["data"]["title"], "Test Card")

    def test_delete_portfolio(self) -> None:
        self.client.post(
            "/portfolio",
            json={"id": "delete-me", "data": {"title": "Delete Card"}},
        )

        response = self.client.delete("/portfolio/delete-me")

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertEqual(payload["deletedId"], "delete-me")


if __name__ == "__main__":
    unittest.main()
