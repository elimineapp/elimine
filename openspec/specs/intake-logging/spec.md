# intake-logging Specification

## Purpose
Recording an intake of a substance in two taps, with an optional past time and dose, and correcting mistakes by editing or deleting an entry, with undo.

## Requirements

### Requirement: Intake time
The substance screen SHALL show the selected time, "Now (today, 14:35)" by default. Tapping it SHALL open a date picker, then a time picker. Chips "Now", "Yesterday" and "Day before" SHALL select the current moment or the same time of day one or two days back. Future times SHALL NOT be accepted: a later time is replaced by the current moment.

#### Scenario: Default time
- **WHEN** the user opens a substance screen at 14:35
- **THEN** the time reads "Now (today, 14:35)"

#### Scenario: Yesterday
- **WHEN** the user taps "Yesterday" at 14:35
- **THEN** the selected time is yesterday at 14:35

#### Scenario: Picking a date and time
- **WHEN** the user taps the time row, picks a date and then a time
- **THEN** the selected time is that date and time

#### Scenario: Future time
- **WHEN** the user picks today at a time later than now
- **THEN** the selected time is the current moment

### Requirement: Dose selection
Under "Dose", the substance screen SHALL show a chip for each dose of the substance, then a "Custom" chip that asks for a number. At most one dose SHALL be selected; tapping the selected dose chip again SHALL clear the selection, and no selection means the intake has no dose. The dose of the last intake SHALL be preselected, with an extra chip if it is not among the substance's doses, and nothing when it had no dose. With no intakes yet, the first dose SHALL be preselected, or nothing when the substance has no doses. A custom dose SHALL accept a comma or a period as the decimal separator and only positive numbers.

#### Scenario: Last dose preselected
- **WHEN** the last intake of a substance with doses 250 and 500 mg was 500 mg
- **THEN** the 500 mg chip is selected when the screen opens

#### Scenario: Custom last dose
- **WHEN** the last intake was a custom 300 mg
- **THEN** a 300 mg chip is shown next to the substance's doses and selected

#### Scenario: Last intake without a dose
- **WHEN** the last intake of a substance with doses 250 and 500 mg had no dose
- **THEN** no dose chip is selected when the screen opens

#### Scenario: Substance without doses
- **WHEN** a substance has no doses and no intakes
- **THEN** only the "Custom" chip is shown and no dose is selected

#### Scenario: Clearing the dose
- **WHEN** the 250 mg chip is selected and the user taps it
- **THEN** no dose chip is selected

#### Scenario: No "No dose" chip
- **WHEN** the substance screen is open
- **THEN** there is no "No dose" chip

#### Scenario: Entering a custom dose
- **WHEN** the user taps "Custom" and enters "1,5"
- **THEN** a 1.5 dose is selected

### Requirement: Logging
The "Log" button SHALL record an intake with the selected dose, or without a dose when no dose is selected, at the selected time. It SHALL always be enabled. After logging, the device SHALL vibrate, the time SHALL reset to "Now" and a snackbar SHALL offer "Undo". When the substance screen is collapsed, it SHALL close and the snackbar SHALL appear on Home. When it is expanded, the user SHALL stay on it and the intake SHALL appear first in the history.

#### Scenario: Logging an intake
- **WHEN** the user taps "Log" with 250 mg selected
- **THEN** a 250 mg intake is recorded at the selected time
- **AND** a snackbar "Logged 250 mg" offers "Undo"

#### Scenario: Logging without a dose
- **WHEN** the user taps "Log" with no dose selected
- **THEN** an intake without a dose is recorded at the selected time
- **AND** a snackbar "Logged" offers "Undo"

#### Scenario: Undo logging
- **WHEN** the user taps "Undo" in that snackbar
- **THEN** the intake disappears from history and analytics

#### Scenario: Logging from the collapsed screen
- **WHEN** the substance screen is collapsed and the user taps "Log"
- **THEN** the substance screen closes
- **AND** Home shows the snackbar and the substance's tile shows the new intake

#### Scenario: Logging from the expanded screen
- **WHEN** the substance screen is expanded and the user taps "Log"
- **THEN** the substance screen stays open and expanded
- **AND** the intake appears first in its history and the snackbar shows on the substance screen

### Requirement: Substance history
The substance screen SHALL list all intakes of the substance, newest first, under "History", or "Nothing logged yet" without intakes. Every intake list SHALL show the dose of each intake that has one, and nothing in its place for an intake without one.

#### Scenario: History order
- **WHEN** a substance has several intakes
- **THEN** its history lists them newest first

#### Scenario: Intake without a dose in a list
- **WHEN** an intake has no dose
- **THEN** its entry in History and in "Recent" shows nothing where the dose would be and never reads "No dose"

### Requirement: Deleting an intake
Swiping an intake away in any list, or tapping "Delete" in its edit sheet, SHALL delete it and show a snackbar "Entry deleted" with "Undo", which restores it unchanged. "Delete" SHALL also close the sheet.

#### Scenario: Delete and undo
- **WHEN** the user swipes an intake away and taps "Undo"
- **THEN** the intake is back with the same time and dose

#### Scenario: Delete from the edit sheet
- **WHEN** the user opens an intake and taps "Delete"
- **THEN** the sheet closes, the intake disappears from every list and analytics
- **AND** a snackbar "Entry deleted" offers "Undo"

### Requirement: Edit sheet
Tapping an intake in any list SHALL open an "Edit entry" sheet titled with the substance's name, showing the intake's time and its dose. The dose SHALL be shown as chips like on the substance screen: the substance's doses, the intake's dose if it is not among them, and "Custom". The intake's dose SHALL be selected, or nothing when it has none; tapping the selected dose SHALL clear it.

#### Scenario: Opening the sheet
- **WHEN** the user taps a 250 mg intake from yesterday at 09:10
- **THEN** the "Edit entry" sheet shows "Yesterday, 09:10" and the 250 mg chip selected

#### Scenario: Intake without a dose
- **WHEN** the user taps an intake without a dose
- **THEN** the sheet shows no dose chip selected

#### Scenario: Custom dose of the intake
- **WHEN** the user taps a 300 mg intake of a substance with doses 250 and 500 mg
- **THEN** the sheet shows a 300 mg chip next to them, selected

### Requirement: Time in the edit sheet
The edit sheet SHALL start from the intake's time. Tapping the time row SHALL open a date picker, then a time picker. Chips "Now", "Yesterday" and "Day before" SHALL select the current moment or the selected time of day one or two days back, as on the substance screen, and "Yesterday" or "Day before" SHALL read as selected when the selected time falls on that day. Future times SHALL NOT be accepted.

#### Scenario: Moving to yesterday
- **WHEN** an intake was logged today at 10:00 and the user taps "Yesterday" in its sheet
- **THEN** the selected time is yesterday at 10:00

#### Scenario: Now
- **WHEN** the user taps "Now" in the sheet
- **THEN** the selected time is the current moment

#### Scenario: Chip of an intake from yesterday
- **WHEN** the user opens an intake from yesterday
- **THEN** the "Yesterday" chip reads as selected

#### Scenario: Future time
- **WHEN** the user picks today at a time later than now in the sheet
- **THEN** the selected time is the current moment

#### Scenario: Time of an intake logged in another time zone
- **WHEN** the intake was logged at 23:30 in UTC+10 and the device is now in UTC+3
- **THEN** the sheet shows 23:30 on the intake's original date

### Requirement: Saving an edited intake
"Save" in the edit sheet SHALL store the selected time and dose, close the sheet and show a snackbar "Entry updated" with "Undo", which restores the previous time and dose. History, "Recent", Home tiles and analytics SHALL reflect the change. Saving without changes SHALL close the sheet without a snackbar. Closing the sheet any other way SHALL keep the intake unchanged.

#### Scenario: Adding a forgotten dose
- **WHEN** the user opens an intake without a dose, selects 250 mg and taps "Save"
- **THEN** the intake has a 250 mg dose and its entry shows "250 mg"
- **AND** a snackbar "Entry updated" offers "Undo"

#### Scenario: Removing a dose
- **WHEN** the user opens a 250 mg intake, taps the selected 250 mg chip and taps "Save"
- **THEN** the intake has no dose

#### Scenario: Changing the time
- **WHEN** the user picks a date three days ago at 20:00 and taps "Save"
- **THEN** the intake is at that date and time, and History reorders accordingly

#### Scenario: Undo an edit
- **WHEN** the user taps "Undo" in the "Entry updated" snackbar
- **THEN** the intake has its previous time and dose again

#### Scenario: Nothing changed
- **WHEN** the user opens the sheet and taps "Save" without changing anything
- **THEN** the sheet closes and no snackbar is shown

#### Scenario: Dismissing the sheet
- **WHEN** the user changes the dose and closes the sheet without tapping "Save"
- **THEN** the intake keeps its previous dose

#### Scenario: Day after a time change
- **WHEN** an intake's time is changed to yesterday
- **THEN** it counts on yesterday's date everywhere intakes are grouped by day

### Requirement: Local day of an intake
Each intake SHALL remember the device time zone offset at the moment it happened. Everything that groups intakes by day SHALL use the local date at that moment, so traveling across time zones does not move past intakes to other days.

#### Scenario: Time zone change
- **WHEN** an intake was logged at 23:30 in UTC+10 and the device later moves to UTC+3
- **THEN** the intake still counts on its original date
