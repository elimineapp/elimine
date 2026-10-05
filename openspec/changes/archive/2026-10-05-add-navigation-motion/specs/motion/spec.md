# Spec Delta

## Purpose

How the app moves between screens: the transitions between tabs and along the path from Home to a substance and its edit screen. Each change of screen shows where the new screen comes from and where it goes back to.

## ADDED Requirements

### Requirement: Switching tabs
Selecting another destination in the bottom navigation bar SHALL fade the current tab out and fade the selected tab in while it settles from a slightly smaller scale. The bottom navigation bar SHALL stay in place. Selecting the destination that is already open SHALL NOT play this transition.

#### Scenario: From Home to Analytics
- **WHEN** Home is open and the user taps "Analytics"
- **THEN** Home fades out and Analytics fades in, growing slightly to its full size
- **AND** the bottom navigation bar does not move

#### Scenario: Selected tab tapped again
- **WHEN** Home is open and the user taps "Home"
- **THEN** no tab transition plays

#### Scenario: State kept across the transition
- **WHEN** the user selects the "Year" range on Analytics, switches to Settings and back
- **THEN** Analytics fades back in already showing the "Year" range

### Requirement: Shared substance icon
The substance icon SHALL move as one element between screens of the same substance. It SHALL travel:
- from a Home tile into the header of its substance screen when it opens;
- from the substance screen header into the edit screen header when it opens;
- back along the same path when those screens close.

#### Scenario: Opening a substance
- **WHEN** the user taps the "Coffee" tile on Home
- **THEN** the "Coffee" icon moves from the tile to its place in the rising substance screen header

#### Scenario: Back from the edit screen
- **WHEN** the edit screen of "Coffee" is open over its substance screen and the user goes back
- **THEN** the icon moves from the edit screen header back into the substance screen header

### Requirement: Edit screen grows from the substance screen
Opening the edit screen from the substance screen SHALL grow the substance screen's surface from its current size to the full screen while its content cross-fades into the edit screen. Going back without saving, or after saving, SHALL reverse this transition into the substance screen in the state it was in, collapsed or expanded.

#### Scenario: From the collapsed sheet
- **WHEN** the collapsed "Coffee" substance screen is open and the user taps its settings action
- **THEN** the sheet's top edge rises to the top of the screen and the edit screen fades in on it

#### Scenario: Back to the collapsed sheet
- **WHEN** the edit screen was opened from the collapsed sheet and the user goes back
- **THEN** the edit screen shrinks down into the collapsed sheet, and the sheet is collapsed again

#### Scenario: Back to the expanded screen
- **WHEN** the edit screen was opened from the expanded substance screen and the user saves
- **THEN** the edit screen cross-fades back into the expanded substance screen

### Requirement: New substance screen grows from its row
Tapping "New substance" on Home SHALL grow the row into the new substance screen. Going back without saving SHALL shrink the screen back into the row. Saving SHALL shrink the screen into the collapsed substance screen of the new substance over Home.

#### Scenario: Opening
- **WHEN** the user taps "New substance"
- **THEN** the row expands to fill the screen and the new substance screen fades in on it

#### Scenario: Cancelling
- **WHEN** the new substance screen is open and the user goes back
- **THEN** the screen shrinks back into the "New substance" row on Home

#### Scenario: Saving
- **WHEN** the user saves the new substance "Tea"
- **THEN** the screen shrinks down into the collapsed "Tea" substance screen over Home, without a moment where neither is shown

### Requirement: Leaving with the substance
When the substance is archived or deleted from its edit screen, the edit screen SHALL first shrink back into the substance screen, and the substance screen SHALL then close downward onto Home, as one continuous motion.

#### Scenario: Archiving
- **WHEN** the user archives "Coffee" from its edit screen opened from the substance screen
- **THEN** the edit screen shrinks into the substance screen, which then slides down and reveals Home without the "Coffee" tile

#### Scenario: Deleting
- **WHEN** the user confirms deleting "Coffee" from its edit screen
- **THEN** the same sequence plays, and the snackbar naming "Coffee" shows on Home after the substance screen has closed

### Requirement: Archive screen transition
The archive screen SHALL open by fading in while it settles from a slightly smaller scale, as Home recedes behind it. Going back SHALL reverse this.

#### Scenario: Opening the archive
- **WHEN** the user taps "Archive (2)" on Home
- **THEN** the archive screen fades in and grows to full size while Home fades back

### Requirement: Back gesture follows the finger
On Android, while the user performs the system back gesture on a screen covered by this capability, its closing transition SHALL play backward in step with the gesture's progress. Releasing the gesture past the commit point SHALL finish closing the screen. Cancelling the gesture SHALL return the screen to how it was.

#### Scenario: Peeking back from the edit screen
- **WHEN** the user starts the back gesture on the edit screen and holds halfway
- **THEN** the edit screen is shown partly shrunk toward the substance screen

#### Scenario: Cancelled gesture
- **WHEN** the user starts the back gesture on the archive screen and cancels it
- **THEN** the archive screen returns to full size and stays open

### Requirement: Transition timing
Every screen and tab transition SHALL finish within 500 ms. Transitions of the same kind SHALL use the same duration and easing throughout the app.

#### Scenario: Tab switch duration
- **WHEN** the user switches from Home to Settings
- **THEN** Settings is fully shown, without movement, within 500 ms

### Requirement: Reduced motion
When the system setting to remove animations is on, screens and tabs SHALL change without movement or scaling. Each change SHALL be a short fade or happen immediately. The shared substance icon SHALL NOT travel.

#### Scenario: Animations removed
- **WHEN** animations are removed in the system settings and the user opens the edit screen from the substance screen
- **THEN** the edit screen appears without the sheet growing and without the icon moving
