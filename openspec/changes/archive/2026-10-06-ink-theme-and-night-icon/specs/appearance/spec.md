# Spec Delta

## ADDED Requirements

### Requirement: Color palette
Both themes SHALL use near-neutral surfaces: backgrounds, cards, sheets and the navigation bar carry no visible hue. The interface accent SHALL come from the launcher icon's ink color `#1B2638`. Substance colors SHALL stay the most vivid colors on any screen, so that interface elements are not mistaken for a substance.

#### Scenario: Light theme
- **WHEN** the app is in the light theme
- **THEN** backgrounds are a warm off-white and cards a slightly darker warm grey, with no green or other visible tint
- **AND** filled buttons, switches and the progress indicator are dark ink

#### Scenario: Dark theme
- **WHEN** the app is in the dark theme
- **THEN** backgrounds are a dark graphite with at most a faint blue cast, with no green tint
- **AND** filled buttons, switches and the progress indicator are a light steel blue

#### Scenario: Substances stand out
- **WHEN** Home shows substances in the "blue", "aqua" and "green" colors
- **THEN** their tiles and badges are the only saturated colors on the screen, and the "New substance" button and the selected navigation item use the ink accent or neutral tones

#### Scenario: Substance colors unchanged
- **WHEN** the app moves to this palette
- **THEN** every substance keeps the color it had before, in both themes
