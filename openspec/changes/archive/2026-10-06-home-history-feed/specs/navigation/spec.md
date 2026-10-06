## ADDED Requirements

### Requirement: Reselecting Home
When Home is shown and its destination is selected, tapping "Home" in the bottom navigation bar again SHALL scroll Home to the top, smoothly, or at once when animations are removed in the system settings. When Home is already at the top, nothing SHALL change.

#### Scenario: Far down the history
- **WHEN** the user has scrolled far down Home and taps "Home" in the bottom navigation bar
- **THEN** Home scrolls to the top and shows the first substance tile

#### Scenario: Already at the top
- **WHEN** Home is at the top and the user taps "Home" in the bottom navigation bar
- **THEN** Home stays as it is

#### Scenario: Switching from another tab
- **WHEN** the user has scrolled Home down, switches to Analytics and then taps "Home"
- **THEN** Home opens at the scroll position it was left at
