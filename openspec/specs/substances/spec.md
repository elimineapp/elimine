# substances Specification

## Purpose
Creating, editing and archiving the user's own substances, each with a unit, a color, an icon and a set of frequent doses.

## Requirements

### Requirement: No built-in substances
The app SHALL NOT ship any built-in substances, doses or presets. Every substance is created by the user.

#### Scenario: Fresh install
- **WHEN** the app is installed and opened for the first time
- **THEN** there are no substances

### Requirement: Substance fields
A substance SHALL have a name (required), a unit (optional, free text), a color, an icon and a list of doses (positive numbers, possibly empty). Leading and trailing spaces SHALL be trimmed from the name and the unit. The unit field SHALL offer suggestion chips "mg", "g", "ml", "pcs", "tab" that fill it in one tap. Without a unit, doses SHALL be shown as plain numbers.

#### Scenario: Missing name or unit
- **WHEN** the user saves the form with an empty name
- **THEN** the name field shows "Required" and nothing is saved
- **AND** an empty unit alone never blocks saving

#### Scenario: No unit
- **WHEN** the user saves a substance with an empty unit and a dose of 2
- **THEN** the substance is saved and the dose is shown as "2"

#### Scenario: Unit suggestion
- **WHEN** the user taps the "mg" suggestion
- **THEN** the unit field contains "mg"

### Requirement: Colors and icons from fixed sets
The color SHALL be chosen from a fixed palette of 8 colors, each with a light-theme and a dark-theme shade, distinguishable from each other including under color vision deficiency. The icon SHALL be chosen from a fixed set. A new substance SHALL default to the first palette color not used by another active substance.

#### Scenario: Default color
- **WHEN** the first two palette colors are used by active substances and the user opens the new substance screen
- **THEN** the third palette color is preselected

### Requirement: Dosage list
Under "Dosage", the user SHALL be able to add doses through an "Add dose" field and remove them. Doses SHALL accept a comma or a period as the decimal separator. Duplicate doses SHALL be stored once, and doses SHALL be shown in ascending order.

#### Scenario: Adding a dose with a comma
- **WHEN** the user enters "0,5" in "Add dose"
- **THEN** a 0.5 dose is added

### Requirement: Unit change warning
When the unit of a substance that has intakes is changed, the app SHALL ask for confirmation, explaining that history is not recalculated. Units are never converted.

#### Scenario: Changing the unit of a used substance
- **WHEN** the user changes the unit of a substance with intakes from "mg" to "g" and saves
- **THEN** a "Change unit?" dialog explains that existing entries keep their numbers under the new unit
- **AND** the change is saved only if the user confirms

### Requirement: Archiving
The edit screen SHALL offer "Archive" with a confirmation. An archived substance SHALL disappear from Home and keep all its intakes, which stay in analytics.

#### Scenario: Archiving a substance
- **WHEN** the user archives a substance and confirms
- **THEN** its tile disappears from Home
- **AND** its intakes still count in Analytics

### Requirement: After creation
After a new substance is saved, the app SHALL open its substance screen in place of the form, so the first intake can be logged right away.

#### Scenario: Saving a new substance
- **WHEN** the user saves a new substance
- **THEN** its substance screen opens and going back returns to Home
