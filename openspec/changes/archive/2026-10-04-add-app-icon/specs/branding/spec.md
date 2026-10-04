# Spec Delta

## Purpose

How the app presents itself to the operating system: its name and launcher icon, recognizable across launcher shapes, themes and Android versions.

## ADDED Requirements

### Requirement: App name
The app SHALL appear in the launcher and system settings under the name "Elimine" in every language.

#### Scenario: Launcher label
- **WHEN** the app is installed on a device in any language
- **THEN** its launcher entry reads "Elimine"

### Requirement: Adaptive launcher icon
On Android versions that support adaptive icons, the launcher icon SHALL be the Elimine icon built from a separate background (a green-to-blue gradient) and foreground (a light and a dark leaf), so the launcher can apply its own mask. Both leaves SHALL stay inside the area every mask keeps visible.

#### Scenario: Circular mask
- **WHEN** the launcher masks icons as circles
- **THEN** the icon shows both leaves on the gradient with no part of them cut off

#### Scenario: Rounded square mask
- **WHEN** the launcher masks icons as rounded squares or squircles
- **THEN** the icon shows both leaves on the gradient

### Requirement: Themed icon
On Android versions with themed icons, the launcher icon SHALL provide a monochrome version of the leaves so that, when the user enables themed icons, the system tints it to match the wallpaper colors like other apps.

#### Scenario: Themed icons enabled
- **WHEN** the user enables themed icons on Android 13 or later
- **THEN** the Elimine icon shows single-color leaves in the system's theme colors

#### Scenario: Themed icons disabled
- **WHEN** themed icons are off
- **THEN** the icon keeps its own colors

### Requirement: Legacy icon
On Android versions without adaptive icons, the launcher SHALL show the full Elimine icon, in a round version where the launcher asks for round icons.

#### Scenario: Older Android
- **WHEN** the app runs on an Android version older than 8.0
- **THEN** the launcher shows the Elimine icon rather than a default icon
