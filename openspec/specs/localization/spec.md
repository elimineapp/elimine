# localization Specification

## Purpose
The languages of the interface and how dates, numbers and plurals follow the user's locale.

## Requirements

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

### Requirement: Locale-aware formatting
Dates, weekday and month names, decimal numbers and plural forms SHALL follow the interface language.

#### Scenario: Russian plurals and decimals
- **WHEN** the interface is Russian
- **THEN** times since an intake use Russian plural forms and decimals use a comma

### Requirement: Time since an intake
The time since an intake SHALL be shown in the step that fits: under a minute "just now"; under an hour minutes; under a day hours and minutes; under 7 days days and hours; under a month days; under a year months and days; under 10 years years and months; from 10 years on years alone. When the second unit is zero, it SHALL be left out and the first unit written as in a single-unit step.

#### Scenario: Under a minute
- **WHEN** an intake was 40 seconds ago
- **THEN** it reads "just now"

#### Scenario: Minutes
- **WHEN** an intake was 12 minutes ago
- **THEN** it reads "12 min ago"

#### Scenario: Hours and minutes
- **WHEN** an intake was 5 hours and 12 minutes ago
- **THEN** it reads "5 h 12 min ago"

#### Scenario: Whole hours
- **WHEN** an intake was 5 hours and 30 seconds ago
- **THEN** it reads "5 h ago"

#### Scenario: Days and hours
- **WHEN** an intake was 3 days and 5 hours ago
- **THEN** it reads "3 d 5 h ago"

#### Scenario: Whole days
- **WHEN** an intake was 3 days and 20 minutes ago
- **THEN** it reads "3 days ago"

#### Scenario: Days within a month
- **WHEN** an intake was 23 days and 4 hours ago
- **THEN** it reads "23 days ago"

#### Scenario: Months and days
- **WHEN** an intake was 4 months and 12 days ago
- **THEN** it reads "4 mo 12 d ago"

#### Scenario: Almost two years
- **WHEN** an intake was 1 year, 11 months and 5 days ago
- **THEN** it reads "1 year 11 mo ago"

#### Scenario: Ten years and more
- **WHEN** an intake was 12 years and 3 months ago
- **THEN** it reads "12 years ago"

#### Scenario: Russian forms
- **WHEN** the interface is Russian
- **THEN** those times read "только что", "12 мин назад", "5 ч 12 мин назад", "5 ч назад", "3 дн. 5 ч назад", "3 дня назад", "23 дня назад", "4 мес. 12 дн. назад", "1 год 11 мес. назад" and "12 лет назад"

### Requirement: Calendar months and years
Months and years since an intake SHALL be counted by the calendar from the intake's local date and time of day: a month has passed on the same day of the next month, and a day that a month lacks SHALL count as that month's last day. Days SHALL be counted as whole days from the intake's time of day, and hours and minutes as the real time passed.

#### Scenario: Anniversary
- **WHEN** an intake was on October 6, 2025 at 10:00 and it is now October 6, 2026 at 10:00
- **THEN** it reads "1 year ago"

#### Scenario: Just before the anniversary
- **WHEN** an intake was on October 6, 2025 at 10:00 and it is now October 6, 2026 at 09:59
- **THEN** it reads "11 mo 29 d ago"

#### Scenario: Short month
- **WHEN** an intake was on January 31, 2026 at 12:00 and it is now February 28, 2026 at 12:00
- **THEN** it reads "1 month ago"

### Requirement: Time since an intake stays current
A time since an intake that is on screen SHALL update by itself at least once a minute, without the user doing anything.

#### Scenario: Minute passes
- **WHEN** Home shows a tile reading "just now" and a minute passes without any input
- **THEN** the tile reads "1 min ago"

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
