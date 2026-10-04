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
A substance SHALL have a name (required), a unit (optional, free text), a color, an icon and a list of doses (positive numbers, possibly empty). Leading and trailing spaces SHALL be trimmed from the name and the unit. The unit field SHALL be labeled "Unit of measure" and SHALL offer suggestion chips "mg", "g", "ml", "pcs", "tab" that fill it in one tap. Without a unit, doses SHALL be shown as plain numbers.

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

#### Scenario: Unit field label
- **WHEN** the user opens the new or edit substance form
- **THEN** the unit field is labeled "Unit of measure"

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
The edit screen SHALL offer "Archive" with a confirmation. An archived substance SHALL disappear from Home and keep all its intakes, which stay in analytics, until it is restored or deleted from the archive screen.

#### Scenario: Archiving a substance
- **WHEN** the user archives a substance and confirms
- **THEN** its tile disappears from Home
- **AND** its intakes still count in Analytics

### Requirement: After creation
After a new substance is saved, the app SHALL return to Home and open that substance's screen collapsed in place of the form, so the first intake can be logged right away.

#### Scenario: Saving a new substance
- **WHEN** the user saves a new substance
- **THEN** Home shows with the new substance's screen open and collapsed
- **AND** closing it leaves Home with the new substance's tile

### Requirement: Deleting a substance
The edit screen SHALL offer "Delete". It SHALL ask for confirmation, naming the substance and the number of its entries and stating that this cannot be undone. On confirmation the substance, its doses and all its intakes SHALL be removed, the app SHALL return to Home and show a snackbar naming the deleted substance. Deleted intakes SHALL disappear from "Recent", history and analytics.

#### Scenario: Deleting a test substance
- **WHEN** the user taps "Delete" on the edit screen of "Test" with 12 entries and confirms
- **THEN** Home opens without a "Test" tile
- **AND** none of its 12 entries appear in "Recent" or Analytics

#### Scenario: Cancelling the deletion
- **WHEN** the user taps "Delete" and then "Cancel"
- **THEN** the substance and its entries are unchanged

### Requirement: Archive screen
The archive screen SHALL list archived substances with their icon, name and number of entries. Each SHALL offer "Restore", which puts it back on Home in its previous place in the order, and "Delete", which deletes it as on the edit screen. When the last archived substance is restored or deleted, the screen SHALL return to Home.

#### Scenario: Restoring a substance
- **WHEN** the user taps "Restore" for an archived substance
- **THEN** its tile is back on Home with its history

#### Scenario: Deleting from the archive
- **WHEN** the user taps "Delete" for an archived substance and confirms
- **THEN** it disappears from the archive along with its entries
