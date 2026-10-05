# Spec Delta

## ADDED Requirements

### Requirement: Substance icon in the form header
The new substance screen and the edit screen SHALL show the substance icon in its color next to their title. The icon SHALL change immediately when the user picks another color or icon, before saving.

#### Scenario: Editing shows the saved look
- **WHEN** the user opens the edit screen of a green "Coffee" with a cup icon
- **THEN** the header shows the green cup icon next to "Edit substance"

#### Scenario: Picking a color
- **WHEN** the user picks red on the edit screen of a green "Coffee"
- **THEN** the header icon turns red before "Save" is tapped

#### Scenario: New substance default
- **WHEN** the user opens the new substance screen
- **THEN** the header shows the icon in the default color for a new substance
