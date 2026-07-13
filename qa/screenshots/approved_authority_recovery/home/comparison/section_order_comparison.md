# Section Order Comparison

Authority: approved S02 Empty Collection crop and Home master board.
Runtime: fresh 01_launch.png and 01_launch.xml.

Approved S02 order:

1. Status bar.
2. Greeting header: Good morning, Harry.
3. Notification icon.
4. Empty collection illustration card.
5. Empty collection message: Your collection is waiting.
6. Primary button: Scan a Collectible.
7. Secondary action: Try a Sample Scan.
8. Popular Categories section with category tiles.
9. Five-item bottom navigation: Home, Scan, Portfolio, Search, Settings.

Current runtime order:

1. Status bar.
2. Header: Your collection, Collector.
3. Disabled notification button.
4. Product Language Hero: Your collection starts here.
5. Primary button: Scan a collectible.
6. Full-width Import photo EntryTile.
7. Full-width Open portfolio EntryTile.
8. Collection snapshot, partially behind App Shell nav in first viewport.
9. Four-item bottom navigation: Home, Portfolio, Scan, Settings.

Finding:

The runtime uses a Product Language composition rather than the approved S02 composition. The largest order deviations are the replacement of the approved empty illustration card, removal of Try a Sample Scan and Popular Categories from the first viewport, insertion of two large EntryTiles before the snapshot, and a four-item App Shell nav where the board shows five destinations.
