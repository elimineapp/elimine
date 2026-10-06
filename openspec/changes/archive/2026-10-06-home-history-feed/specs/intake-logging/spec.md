## MODIFIED Requirements

### Requirement: Substance history
The substance screen SHALL list all intakes of the substance, newest first, under "History", or "Nothing logged yet" without intakes. Every intake list SHALL show the dose of each intake that has one, and nothing in its place for an intake without one.

#### Scenario: History order
- **WHEN** a substance has several intakes
- **THEN** its history lists them newest first

#### Scenario: Intake without a dose in a list
- **WHEN** an intake has no dose
- **THEN** its entry in the substance history and in "History" on Home shows nothing where the dose would be and never reads "No dose"

### Requirement: Saving an edited intake
"Save" in the edit sheet SHALL store the selected time and dose, close the sheet and show a snackbar "Entry updated" with "Undo", which restores the previous time and dose. The substance history, "History" on Home, Home tiles and analytics SHALL reflect the change. Saving without changes SHALL close the sheet without a snackbar. Closing the sheet any other way SHALL keep the intake unchanged.

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
