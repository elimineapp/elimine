# Spec Delta

## Purpose

How the substance screen is presented. It is a sheet over Home that opens collapsed for quick logging and expands into the full screen with the chart and history.

## ADDED Requirements

### Requirement: Collapsed substance screen
Tapping a substance tile on Home SHALL open its substance screen as a sheet rising over Home in its collapsed state. The collapsed sheet SHALL show:
- a drag handle;
- the substance icon and name, the last intake as on its Home tile, and a settings action that opens the edit screen;
- the time, dose and "Log" controls;
- a "Chart and history" row showing the number of intakes, with the top of the dose chart visible below it.

#### Scenario: Opening a substance
- **WHEN** the user taps the "Coffee" tile on Home
- **THEN** the "Coffee" substance screen rises from the bottom in its collapsed state
- **AND** Home stays visible, dimmed, above it

#### Scenario: Collapsed content
- **WHEN** the substance screen of a substance with 14 intakes is collapsed
- **THEN** it shows the time, dose and "Log" controls, then a "Chart and history" row with 14
- **AND** the top edge of the dose chart shows below that row

### Requirement: Expanding the substance screen
Dragging the collapsed sheet up, or tapping "Chart and history", SHALL expand the substance screen to fill the whole screen. The expanded screen SHALL have a header with a "Collapse" action, the substance icon and name, and the settings action. Below the header SHALL scroll the time, dose and "Log" controls, the dose chart and the history.

#### Scenario: Dragging up
- **WHEN** the user drags the collapsed sheet upward
- **THEN** the substance screen expands to the full screen, showing the dose chart and the history

#### Scenario: Tapping the row
- **WHEN** the user taps "Chart and history"
- **THEN** the substance screen expands to the full screen

### Requirement: Collapsing and closing
On the expanded screen, "Collapse" or dragging down from the top of its content SHALL collapse it. Dragging the collapsed sheet down, or tapping Home above it, SHALL close it. System back SHALL close the substance screen in either state and return to Home.

#### Scenario: Collapsing
- **WHEN** the expanded screen is scrolled to the top and the user drags it down
- **THEN** it collapses

#### Scenario: Closing the collapsed sheet
- **WHEN** the user drags the collapsed sheet down or taps Home above it
- **THEN** the substance screen closes and Home is shown

#### Scenario: Back from the expanded screen
- **WHEN** the substance screen is expanded and the user presses system back
- **THEN** the substance screen closes and Home is shown

### Requirement: Expand hint
Until the user has expanded a substance screen for the first time, opening a substance screen SHALL briefly lift the collapsed sheet and let it settle back, showing that it can be pulled up. Once a substance screen has been expanded, the hint SHALL NOT be shown again. This SHALL be kept on the device across restarts and SHALL NOT be part of backup files.

#### Scenario: Before the first expansion
- **WHEN** the user has never expanded a substance screen and opens one
- **THEN** the collapsed sheet lifts briefly and settles back

#### Scenario: After the first expansion
- **WHEN** the user has expanded a substance screen once and later opens any substance screen
- **THEN** the sheet opens collapsed without lifting

### Requirement: Leaving with the substance
When the substance is archived or deleted from its edit screen, the app SHALL return to Home with its substance screen closed.

#### Scenario: Archiving from the substance screen
- **WHEN** the user opens the edit screen from a substance screen and archives the substance
- **THEN** Home is shown without the substance screen and without that substance's tile
