# CollectIQ AI Validation Lab Report

- Generated: 2026-06-30T07:19:13Z
- Manifest: C:\Users\hario\Desktop\projects\collectiq_ai\validation\manifests\sample_manifest.json
- Endpoint: http://127.0.0.1:8000/api/analyze

## Metrics

- Total images: 3
- Analyzed images: 0
- Failed image count: 3
- Category accuracy: n/a
- Name keyword match accuracy: n/a
- Set match accuracy: n/a
- Year match accuracy: n/a
- Price in expected range: n/a
- Average latency: 0 ms
- Low-confidence count: 0

## Results

| File | Status | Expected | Actual | Category | Confidence | Latency | Error |
| --- | --- | --- | --- | --- | --- | --- | --- |
| pokemon_card_placeholder.jpg | missing_image | 1999 Pokemon Charizard Holo |  |  |  |  | Image file is missing from validation/images. |
| sports_card_placeholder.jpg | missing_image | 1986 Fleer Michael Jordan Rookie |  |  |  |  | Image file is missing from validation/images. |
| coin_placeholder.jpg | missing_image | 1921 Morgan Silver Dollar |  |  |  |  | Image file is missing from validation/images. |

Automated tests must run in mock/default mode. Real OpenAI/eBay validation is manual/local only.
