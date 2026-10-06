# Spec Delta

## MODIFIED Requirements

### Requirement: Supported languages
The interface SHALL be available in English and Russian. Unless the user chose a language on the Settings screen, it SHALL follow the device language, falling back to English for other languages. User-entered text such as substance names and units SHALL be shown as entered.

#### Scenario: Russian device
- **WHEN** the device language is Russian and the "Language" setting is "System"
- **THEN** the interface is in Russian

#### Scenario: Unsupported language
- **WHEN** the device language is German and the "Language" setting is "System"
- **THEN** the interface is in English

#### Scenario: Chosen language wins
- **WHEN** the device language is English and the user chose "Русский"
- **THEN** the interface is in Russian

## ADDED Requirements

### Requirement: Language choice
The "General" section of the Settings screen SHALL have a "Language" row showing the current choice, "System" by default. Tapping it SHALL offer "System", "English" and "Русский". Language names SHALL be written in their own language whatever the interface language is; "System" SHALL be translated. The choice SHALL apply at once, without a restart, to the whole interface, including dates, numbers and plurals.

#### Scenario: Switching to Russian
- **WHEN** the interface is in English and the user chooses "Русский"
- **THEN** the Settings screen and every other screen are in Russian at once
- **AND** the "Language" row shows "Русский"

#### Scenario: Back to the device language
- **WHEN** the device language is English, the user had chosen "Русский" and now chooses "System"
- **THEN** the interface is in English

#### Scenario: Names in their own language
- **WHEN** the interface is in Russian and the user taps "Language"
- **THEN** the options read "Системный", "English" and "Русский"

### Requirement: Language choice is kept
The language choice SHALL be kept on the device across restarts, and the app SHALL open in the chosen language from its first frame. It SHALL NOT be part of backup files.

#### Scenario: Kept after restart
- **WHEN** the user chose "Русский" on an English device and restarts the app
- **THEN** the app opens in Russian without first showing English
- **AND** the "Language" row still shows "Русский"

#### Scenario: Not in backups
- **WHEN** the user chose "Русский" and exports a backup
- **THEN** the backup file does not contain the language choice
