# intake-logging Specification

## Purpose
Recording an intake of a substance in two taps, with an optional past time and dose, and correcting mistakes through deletion and undo.

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
Under "Dose", the substance screen SHALL show a "No dose" chip first, then a chip for each dose of the substance, then a "Custom" chip that asks for a number. Exactly one option SHALL be selected at any time. The dose of the last intake SHALL be preselected: "No dose" if it had none, and an extra chip if its dose is not among the substance's doses. With no intakes yet, the first dose SHALL be preselected, or "No dose" when the substance has no doses. A custom dose SHALL accept a comma or a period as the decimal separator and only positive numbers.

#### Scenario: Last dose preselected
- **WHEN** the last intake of a substance with doses 250 and 500 mg was 500 mg
- **THEN** the 500 mg chip is selected when the screen opens

#### Scenario: Custom last dose
- **WHEN** the last intake was a custom 300 mg
- **THEN** a 300 mg chip is shown next to the substance's doses and selected

#### Scenario: Last intake without a dose
- **WHEN** the last intake of a substance with doses 250 and 500 mg had no dose
- **THEN** the "No dose" chip is selected when the screen opens

#### Scenario: Substance without doses
- **WHEN** a substance has no doses and no intakes
- **THEN** the "No dose" chip is selected

#### Scenario: Entering a custom dose
- **WHEN** the user taps "Custom" and enters "1,5"
- **THEN** a 1.5 dose is selected

### Requirement: Logging
The "Log" button SHALL record an intake with the selected dose, or without a dose when "No dose" is selected, at the selected time. It SHALL always be enabled. After logging, the device SHALL vibrate, the user SHALL stay on the substance screen, the intake SHALL appear first in the history, a snackbar SHALL offer "Undo", and the time SHALL reset to "Now".

#### Scenario: Logging an intake
- **WHEN** the user taps "Log" with 250 mg selected
- **THEN** a 250 mg intake is recorded at the selected time
- **AND** a snackbar "Logged 250 mg" offers "Undo"

#### Scenario: Logging without a dose
- **WHEN** the user taps "Log" with "No dose" selected
- **THEN** an intake without a dose is recorded at the selected time
- **AND** a snackbar "Logged" offers "Undo"

#### Scenario: Undo logging
- **WHEN** the user taps "Undo" in that snackbar
- **THEN** the intake disappears from history and analytics

### Requirement: Substance history
The substance screen SHALL list all intakes of the substance, newest first, under "History", or "Nothing logged yet" without intakes. Every intake list SHALL show the dose of each intake, or "No dose" for an intake without one.

#### Scenario: History order
- **WHEN** a substance has several intakes
- **THEN** its history lists them newest first

#### Scenario: Intake without a dose in a list
- **WHEN** an intake has no dose
- **THEN** its entry in History and in "Recent" reads "No dose" where the dose would be

### Requirement: Deleting an intake
Swiping an intake away in any list SHALL delete it and show a snackbar "Entry deleted" with "Undo", which restores it unchanged.

#### Scenario: Delete and undo
- **WHEN** the user swipes an intake away and taps "Undo"
- **THEN** the intake is back with the same time and dose

### Requirement: Local day of an intake
Each intake SHALL remember the device time zone offset at the moment it happened. Everything that groups intakes by day SHALL use the local date at that moment, so traveling across time zones does not move past intakes to other days.

#### Scenario: Time zone change
- **WHEN** an intake was logged at 23:30 in UTC+10 and the device later moves to UTC+3
- **THEN** the intake still counts on its original date
