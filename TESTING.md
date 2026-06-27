# Testing

## Run Tests

```bash
flutter analyze
flutter test
```

## Covered

- Home, Scanner, Portfolio, and Settings screen loading
- Bottom navigation between main tabs
- Scanner sample scan flow
- AI analysis success rendering
- AI analysis backend failure message
- Portfolio empty state, saved item display, and delete flow
- `CollectibleItem.toJson()` and `CollectibleItem.fromJson()`
- Shared preferences portfolio repository add, load, and remove behavior
- Backend recognition response parsing into `RecognitionResult`

## Mocking

Widget tests override the AI recognition service with fake implementations, so tests do not require the local FastAPI backend or any external API.

## Still Manual

- Real camera capture on physical devices
- Gallery picker integration
- Multipart upload against the running FastAPI backend
- Platform permissions for camera and photos
- Visual QA across device sizes
