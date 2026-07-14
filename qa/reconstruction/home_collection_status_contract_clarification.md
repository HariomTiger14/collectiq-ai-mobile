# Home Collection Status Contract Clarification

Date: 2026-07-14

Scope: Empty-state Home `Collection Status` only.

## Supported Metrics

| Metric | Source | Empty-state value | Classification | Notes |
| --- | --- | --- | --- | --- |
| Items | `portfolioControllerProvider.orderedItems.length` | `0` | real | Genuine zero; not unavailable. |
| Estimated value | Existing valuation aggregation when valued items exist | `-` | unavailable | No collection value exists before saved items. Do not render `$0` unless a real zero-valued market/AI estimate exists. |
| Average condition | Saved item condition data only | `-` | unavailable | No average is calculated for an empty collection. |
| Scans | Existing empty-state placeholder only | `0` | real empty placeholder | Represents no saved scan-derived items in the empty local portfolio; does not introduce scan-history analytics. |

## Intentionally Omitted

- Trends: omitted because Home has no real empty-state trend data.
- Confidence: omitted because confidence belongs to scan results, not empty Home.
- Readiness: omitted because it would fabricate state.
- Category counts: omitted in empty state because no category distribution exists.
- Last scan: omitted in empty state because there is no saved item timestamp.

## Visual Role

`Collection Status` must behave as a compact dashboard summary, not a second empty-state card. It must not repeat:

- `Your collection is waiting`
- `Scan your first item to get started.`
- `Scan a Collectible`

The one footer line is limited to explaining unavailable values: `Value and condition stay unavailable until items are saved.`

## Preserved Contracts

- No fabricated collection value.
- No fake average condition.
- No fake scan history.
- Genuine zero remains visible as `0`.
- Unavailable values remain `-`.
- Portfolio ownership remains with `portfolioControllerProvider`.
