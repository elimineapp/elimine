# Spec Delta

## MODIFIED Requirements

### Requirement: Substance tiles
Home SHALL show every active (not archived) substance as a tile in a two-column grid, in the user's substance order. A tile SHALL show the substance icon in its color, the name without the unit, and the last intake as its dose and a relative day ("today", "yesterday", "12 days ago", "2 months ago"), or only the relative day when that intake had no dose. A substance without intakes SHALL show "Not logged yet". Tapping a tile SHALL open the substance screen.

#### Scenario: Name without the unit
- **WHEN** a substance "Coffee" has the unit "mg"
- **THEN** its tile shows "Coffee", not "Coffee, mg"

#### Scenario: Tile with history
- **WHEN** a substance's last intake was 250 mg twelve days ago
- **THEN** its tile shows "250 mg · 12 days ago"

#### Scenario: Last intake without a dose
- **WHEN** a substance's last intake had no dose and was yesterday
- **THEN** its tile shows "yesterday"

#### Scenario: Tile without history
- **WHEN** a substance has no intakes
- **THEN** its tile shows "Not logged yet"

#### Scenario: Archived substance
- **WHEN** a substance is archived
- **THEN** it has no tile on Home
