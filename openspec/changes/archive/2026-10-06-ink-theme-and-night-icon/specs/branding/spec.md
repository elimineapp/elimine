# Spec Delta

## MODIFIED Requirements

### Requirement: Adaptive launcher icon
On Android versions that support adaptive icons, the launcher icon SHALL be the Elimine icon built from a separate background (flat ink with a soft light highlight toward the top left) and foreground (a light leaf and a blue leaf), so the launcher can apply its own mask. Both leaves SHALL stay inside the area every mask keeps visible.

#### Scenario: Circular mask
- **WHEN** the launcher masks icons as circles
- **THEN** the icon shows both leaves on the ink background with no part of them cut off

#### Scenario: Rounded square mask
- **WHEN** the launcher masks icons as rounded squares or squircles
- **THEN** the icon shows both leaves on the ink background

#### Scenario: Dark wallpaper
- **WHEN** the launcher shows the icon on a dark wallpaper
- **THEN** both leaves stay clearly visible against the ink background
