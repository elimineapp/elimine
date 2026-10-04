# Spec Delta

## MODIFIED Requirements

### Requirement: Substance tiles
Home SHALL show every active (not archived) substance as a full-width tile in a single column, in the user's substance order. A tile SHALL be tinted with the substance color and SHALL show the substance icon on a circle filled with that color, the name without the unit on up to two lines, and the last intake as its dose and a relative day ("today", "yesterday", "12 days ago", "2 months ago"), or only the relative day when that intake had no dose. A substance without intakes SHALL show "Not logged yet". Tapping a tile SHALL open the substance screen.

#### Scenario: Name without the unit
- **WHEN** a substance "Coffee" has the unit "mg"
- **THEN** its tile shows "Coffee", not "Coffee, mg"

#### Scenario: Long name
- **WHEN** a substance's name does not fit on one line of its tile
- **THEN** the name wraps onto a second line and is cut with an ellipsis only after that line

#### Scenario: Tile color
- **WHEN** a substance has the color "orange"
- **THEN** its tile is tinted orange and its icon sits on an orange circle

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

### Requirement: New substance tile
The last item of the substance list SHALL be a "New substance" row, which opens the new substance screen. On first launch, with no substances, it SHALL be the only item.

#### Scenario: First launch
- **WHEN** the app starts with no data
- **THEN** Home shows only the "New substance" row

## ADDED Requirements

### Requirement: Intake weeks on a tile
Each substance tile SHALL show a strip of 12 marks for the 12 calendar weeks ending with the current week, oldest on the left. A mark SHALL be filled with the substance color when the substance had at least one intake that week, with or without a dose, and SHALL be empty otherwise. A filled mark SHALL be faint for one intake, stronger for two and in the full substance color for three or more. Weeks SHALL start on the day chosen in Settings, and an intake SHALL count in the week of its local day.

#### Scenario: Intake this week
- **WHEN** a substance was taken today
- **THEN** the rightmost mark of its tile is filled

#### Scenario: Intake twelve days ago
- **WHEN** today is Sunday, October 4, weeks start on Monday and the substance's only intake was on Tuesday, September 22
- **THEN** only the second mark from the right is filled

#### Scenario: Intake without a dose
- **WHEN** the substance's only intake this week had no dose
- **THEN** the rightmost mark is filled

#### Scenario: Several intakes in a week
- **WHEN** a substance was taken once in one week, twice in another and four times in a third
- **THEN** the first of those marks is the faintest, the second stronger, and the third in the full substance color

#### Scenario: Older intakes
- **WHEN** a substance's last intake was more than 12 weeks ago
- **THEN** all marks of its tile are empty

#### Scenario: Week starting on Sunday
- **WHEN** weeks start on Sunday, today is Sunday, October 4, and the substance was taken only on Saturday, October 3
- **THEN** only the second mark from the right is filled
