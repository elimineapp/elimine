# home Specification

## Purpose
The start screen: one tap from any active substance and an overview of the latest intakes across all substances.

## Requirements

### Requirement: Header
Home SHALL show the app name and the current date in its header, and no other actions. Settings is reached through the bottom navigation bar.

#### Scenario: Header content
- **WHEN** Home is open
- **THEN** the header shows "Elimine" and today's date in the current locale

#### Scenario: Opening Settings
- **WHEN** Home is open
- **THEN** its header has no settings action
- **AND** Settings is opened through "Settings" in the bottom navigation bar

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

### Requirement: New substance tile
The last item of the substance list SHALL be a "New substance" row, which opens the new substance screen. On first launch, with no substances, it SHALL be the only item.

#### Scenario: First launch
- **WHEN** the app starts with no data
- **THEN** Home shows only the "New substance" row

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
