# Spacing And Alignment Comparison

Authority: approved S02 Empty Collection crop and Home master board.
Runtime: fresh 01_launch.png and source mapping.

Measured runtime facts:

- Device capture is 1080x2400 physical pixels.
- Status bar occupies 0..92 px.
- App content starts at y=92 px.
- Runtime horizontal content padding is 45 px on the 1080 px capture, corresponding to AppSpacing.lg at density 2.8125.
- Runtime Hero bounds from XML are [45,337][1035,1093], width 990 px, height 756 px.
- Runtime action group bounds are [45,1127][1035,1667], height 540 px.
- Runtime nav bounds are [34,2029][1046,2173], height 144 px, above the 135 px Android nav bar.

Approved crop facts:

- S02 crop is 127x426 px and represents a board-extracted mobile frame, not a same-pixel device capture.
- The approved first viewport keeps empty-state card, button, secondary action, category tiles, and bottom nav visible in one crop.

Comparison rule:

Pixel-perfect claims are invalid because the approved crop and runtime capture have different image dimensions and different device framing. Relative proportion is the correct comparison basis.

Finding:

Runtime allocates too much first-viewport height to the Hero plus two EntryTiles before showing the collection snapshot. Approved S02 allocates first viewport height to the empty state card and category tiles, with less vertical weight given to secondary actions.
