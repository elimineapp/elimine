# Spec Delta

## ADDED Requirements

### Requirement: Reordering substance tiles
Long-pressing a substance tile on Home SHALL lift it under the finger, and dragging it SHALL move it among the other tiles, which make room for it. Releasing it SHALL drop it in that place. A short tap SHALL still open the substance screen. The "New substance" row SHALL stay last: it SHALL NOT be draggable, and no tile SHALL be dropped below it.

#### Scenario: Moving a tile up
- **WHEN** Home shows "Coffee", "Melatonin" and "Ibuprofen" in that order and the user long-presses "Ibuprofen" and drags it above "Coffee"
- **THEN** Home shows "Ibuprofen", "Coffee", "Melatonin"

#### Scenario: Tap still opens
- **WHEN** the user taps a substance tile without holding it
- **THEN** the substance screen opens and the order does not change

#### Scenario: New substance row stays last
- **WHEN** the user drags a tile past the "New substance" row
- **THEN** the tile is dropped just above "New substance"
- **AND** "New substance" remains the last item of the list

#### Scenario: Long list
- **WHEN** the user drags a tile to the edge of the visible part of Home and more tiles lie beyond it
- **THEN** Home scrolls so that the tile can be dropped there

### Requirement: Saved substance order
The order set by dragging SHALL be saved on the device when the tile is dropped and SHALL be kept after the app restarts. A new substance SHALL appear after all existing ones. An archived substance SHALL keep its place relative to the others, so that "Restore" puts it back between the same neighbors even if other tiles were moved in the meantime. A backup SHALL keep the order.

#### Scenario: After a restart
- **WHEN** the user moves "Ibuprofen" to the top and restarts the app
- **THEN** "Ibuprofen" is still the first tile on Home

#### Scenario: New substance after reordering
- **WHEN** the user has reordered the tiles and then creates "Vitamin D"
- **THEN** "Vitamin D" is the last tile, just above "New substance", and the other tiles keep their order

#### Scenario: Restoring after reordering
- **WHEN** the order is "Coffee", "Melatonin", "Ibuprofen", the user archives "Melatonin", moves "Ibuprofen" above "Coffee" and restores "Melatonin"
- **THEN** Home shows "Ibuprofen", "Coffee", "Melatonin"

#### Scenario: Backup keeps the order
- **WHEN** the user exports a backup after reordering and imports it on a device without substances
- **THEN** Home shows the substances in the same order

### Requirement: Moving tiles with a screen reader
Each substance tile SHALL offer the accessibility actions "Move up" and "Move down", which move it one place in the order and save it like a drag. The first tile SHALL NOT offer "Move up", and the last tile SHALL NOT offer "Move down".

#### Scenario: Move down with a screen reader
- **WHEN** Home shows "Coffee" and "Melatonin" and the user activates "Move down" on "Coffee"
- **THEN** Home shows "Melatonin", "Coffee" and the order is saved

#### Scenario: Edges of the list
- **WHEN** a screen reader focuses the first tile
- **THEN** it offers "Move down" but not "Move up"
