# Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Deleting an intake
Swiping an intake away in any list, or tapping "Delete" in its edit sheet, SHALL delete it and show a snackbar "Entry deleted" with "Undo", which restores it unchanged. "Delete" SHALL also close the sheet.

#### Scenario: Delete and undo
- **WHEN** the user swipes an intake away and taps "Undo"
- **THEN** the intake is back with the same time and dose

#### Scenario: Delete from the edit sheet
- **WHEN** the user opens an intake and taps "Delete"
- **THEN** the sheet closes, the intake disappears from every list and analytics
- **AND** a snackbar "Entry deleted" offers "Undo"
