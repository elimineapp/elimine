# Spec Delta

## MODIFIED Requirements

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
