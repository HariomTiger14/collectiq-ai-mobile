# Detail Phase 3 Contract Clarifications

Phase 3 does not change Detail business ownership.

Preserved contracts:
- Portfolio remains the owner of saved item identity and navigation into Detail.
- Repository/sync state remains stored state; Detail only renders saved sync status and error text.
- Primary image, gallery ordering, thumbnail selection, review carousel, edit image, primary selection, and delete image behavior remain unchanged.
- Notes, wishlist status, price alerts, share feedback, favorite feedback, item edit, and item delete use existing handlers.
- AI Insights render only stored `aiReasoning`, `confidenceExplanation`, and `detectionQuality` evidence.
- Market presentation renders only stored `PricingInfo` and `MarketSummary` values.

Clarified valuation behavior:
- `marketEstimated` and `aiEstimated` statuses may honestly render `$0` when zero is saved.
- `providerNotConfigured`, `noMarketMatch`, `lookupFailed`, and `unavailable` render `Value unavailable` unless a positive legacy value is saved.

Out of scope:
- No Home, Portfolio, Scanner, Settings, Search, Notifications, App Shell lifecycle, backend, auth, routing, or Product Language definition changes were made.
