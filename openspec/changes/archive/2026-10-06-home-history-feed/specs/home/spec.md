## MODIFIED Requirements

### Requirement: Substance tiles
Home SHALL show every active (not archived) substance as a full-width tile in a single column, in the user's substance order. A tile SHALL be tinted with the substance color and SHALL show the substance icon on a circle filled with that color, the name without the unit on up to two lines, and the last intake as its dose and the time since it, as defined by the localization capability ("12 days ago", "1 year 11 mo ago"), or only the time since it when that intake had no dose. A substance without intakes SHALL show "Not logged yet". Tapping a tile SHALL open the substance screen.

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
- **WHEN** a substance's last intake had no dose and was 5 hours and 12 minutes ago
- **THEN** its tile shows "5 h 12 min ago"

#### Scenario: Long abstinence
- **WHEN** a substance's last intake was 0.5 l, one year, eleven months and five days ago
- **THEN** its tile shows "0.5 l · 1 year 11 mo ago"

#### Scenario: Tile without history
- **WHEN** a substance has no intakes
- **THEN** its tile shows "Not logged yet"

#### Scenario: Archived substance
- **WHEN** a substance is archived
- **THEN** it has no tile on Home

### Requirement: Archive entry
When at least one substance is archived, Home SHALL show an "Archive (N)" row directly below the "New substance" row and above "History", N being the number of archived substances. The row SHALL open the archive screen. Without archived substances the row SHALL NOT be shown.

#### Scenario: Archived substances exist
- **WHEN** two substances are archived
- **THEN** Home shows "Archive (2)" between "New substance" and "History", and it opens the archive screen

#### Scenario: Long history
- **WHEN** a substance is archived and there are hundreds of intakes
- **THEN** "Archive (1)" is reached without scrolling through the history

#### Scenario: Nothing archived
- **WHEN** no substance is archived
- **THEN** Home shows no archive row and "History" follows "New substance"

## REMOVED Requirements

### Requirement: Recent intakes
**Reason**: The fixed list of the 10 latest intakes is replaced by the endless "History" feed.
**Migration**: See the "History feed" requirement. Every intake, not just the latest 10, is reachable from Home.

## ADDED Requirements

### Requirement: History feed
Home SHALL list all intakes across all substances under "History", newest first, each with its date and time, substance and dose. Older intakes SHALL load as the user scrolls toward the end of the list, without a button, until the oldest one is shown. Entries already shown SHALL stay in place while more load. Without intakes "History" SHALL show "Nothing logged yet". Tapping an entry SHALL open its edit sheet and swiping it away SHALL delete it, as defined by the intake-logging capability.

#### Scenario: History order
- **WHEN** intakes of several substances exist
- **THEN** "History" lists them across substances, newest first

#### Scenario: Scrolling to older intakes
- **WHEN** there are 300 intakes and the user keeps scrolling down "History"
- **THEN** older intakes keep appearing until the oldest one is shown
- **AND** the list does not jump back while they load

#### Scenario: Empty history
- **WHEN** there are no intakes
- **THEN** "History" shows "Nothing logged yet"

#### Scenario: Editing from History
- **WHEN** the user taps an entry under "History"
- **THEN** the "Edit entry" sheet for that intake opens on Home

### Requirement: Back to top
When Home is scrolled down by more than twice its visible height and the user scrolls up, Home SHALL show a "Back to top" button above the bottom navigation bar. Scrolling down or coming within that distance of the top SHALL hide it. Tapping it SHALL scroll Home to the top, smoothly, or at once when animations are removed in the system settings.

#### Scenario: Scrolling up far down the feed
- **WHEN** the user has scrolled far down "History" and starts scrolling up
- **THEN** the "Back to top" button appears

#### Scenario: Scrolling down
- **WHEN** the "Back to top" button is shown and the user scrolls down
- **THEN** the button hides

#### Scenario: Near the top
- **WHEN** Home is scrolled down by less than twice its visible height
- **THEN** the "Back to top" button is not shown

#### Scenario: Going back to the top
- **WHEN** the user taps "Back to top"
- **THEN** Home scrolls to the top and shows the first substance tile
- **AND** the button hides

#### Scenario: Animations removed
- **WHEN** animations are removed in the system settings and the user taps "Back to top"
- **THEN** Home shows its top at once, without scrolling through the feed
