# Proposal

## Why

Home shows only the 10 latest intakes, so anything older is reachable only substance by substance. The last intake reads coarsely: 705 days ago shows as "1 year ago", which hides that almost two years have passed. That number matters when the point is how long the user has gone without a substance. Archived substances, often the ones the user stopped taking, do not show their last intake at all.

## What Changes

- **BREAKING (UI)**: "Recent" on Home becomes "History", an endless feed of all intakes, newest first, that loads older entries as the user scrolls.
- The "Archive (N)" row moves from the end of Home, which the endless feed makes unreachable, to just below "New substance" and above "History".
- Tapping the already selected "Home" in the bottom navigation scrolls Home back to the top.
- A "Back to top" button appears on Home when the user is far down the feed and scrolls up, and hides when they scroll down.
- The archive screen shows each substance's last intake as on its Home tile, next to its number of entries.
- **BREAKING (UI)**: the last intake shows the elapsed time in two units where it matters: "just now", "12 min ago", "5 h 12 min ago", "3 d 5 h ago", "23 days ago", "4 mo 12 d ago", "1 year 11 mo ago", "12 years ago". "today" and "yesterday" are no longer used there. Months and years follow the calendar. On-screen values update at least once a minute.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `home`: "Recent" is replaced by the endless "History" feed. The archive row moves. A "Back to top" button is added. Tiles use the new elapsed time format.
- `localization`: adds the elapsed time format and its Russian forms.
- `navigation`: reselecting "Home" scrolls it to the top.
- `substances`: the archive screen shows the last intake. References to "Recent" become "History" on Home.
- `intake-logging`: references to "Recent" become "History" on Home.

## Impact

- Home screen: paged history feed, archive row position, "Back to top" button, scroll controller shared with the bottom navigation.
- Database queries: the recent-intakes query takes a growing limit. The archived-substances query also returns each substance's last intake. No migration.
- Formatting: the relative-day formatter is replaced by an elapsed time formatter with calendar month and year arithmetic. New and changed strings in English and Russian.
- A once-a-minute tick refreshes elapsed times on Home, the substance screen header and the archive screen.
- Tests: format, Home, archive and navigation tests change.
