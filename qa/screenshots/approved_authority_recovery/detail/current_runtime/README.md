# Current Detail Runtime Evidence

Device: Samsung SM E625F, Android 13 / API 33, `RZ8R213M8ZL`
Build: local debug APK, `com.collectiq.ai.local`
Flutter device discovery: passed
Local debug build: passed, `build/app/outputs/flutter-apk/app-local-debug.apk`
Install: passed
Physical size: 1080x2400
Physical density: 450
Text scale: 1.0
System night mode: no
Runtime seed: debug-only SharedPreferences seed copied into the local debug app sandbox through `run-as com.collectiq.ai.local`

## Captured States

- `01_launch_home.png/xml`: seeded Home with two collectibles
- `02_portfolio_seeded.png/xml`: Portfolio handoff and seeded list
- `03_portfolio_item_visible.png/xml`: populated item visible for Detail entry
- `04_detail_first_viewport.png/xml`: Detail header, image hero, filmstrip, identity, value
- `05_detail_ai_metadata_notes.png/xml`: AI Review, key attributes, notes
- `06_detail_actions_value.png/xml`: actions/value slice
- `07_detail_gallery_state.png/xml`: hero/gallery state
- `08_gallery_review.png/xml`: full-screen gallery review
- `09_detail_actions_before.png/xml`: notes/actions vicinity
- `10_detail_action_controls.png/xml`: Edit, Share, Favorite, Delete controls
- `11_favorite_feedback.png/xml`: Favorite action feedback
- `12_share_feedback.png/xml`: Share action feedback
- `13_delete_confirmation.png/xml`: delete confirmation, not confirmed
- `14_return_to_portfolio.png/xml`: return to Portfolio
- `15_portfolio_minimal_visible.png/xml`: minimal item visible
- `16_minimal_missing_image_unavailable_value.png/xml`: missing image and unavailable/zero-value item runtime
- `17_runtime_logcat.txt`: Android log capture

## Availability Notes

Fresh runtime evidence covered first viewport, scroll, primary image, thumbnail strip, full-screen review, valuation, unavailable/zero-value item, metadata, stored AI evidence, notes, favorite, share, delete confirmation, Portfolio return, multi-image item, missing-image item, hierarchy XML, device dimensions, text scale, theme, and system bars.

The runtime did not provide a separate approved local/demo mechanism for absent AI evidence beyond the minimal item state. It also did not provide a true price-history series; runtime evidence preserves the app's saved-market-evidence behavior rather than fabricating price history.

## Log Result

No app crash was identified in the focused Detail runtime. Logcat contains unrelated system/package noise. No `FATAL EXCEPTION` or `E/flutter` line was observed for `com.collectiq.ai.local` during the captured Detail path.
