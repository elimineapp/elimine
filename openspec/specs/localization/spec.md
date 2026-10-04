# localization Specification

## Purpose
The languages of the interface and how dates, numbers and plurals follow the user's locale.

## Requirements

### Requirement: Supported languages
The interface SHALL be available in English and Russian and follow the device language, falling back to English for other languages. User-entered text such as substance names and units SHALL be shown as entered.

#### Scenario: Russian device
- **WHEN** the device language is Russian
- **THEN** the interface is in Russian

#### Scenario: Unsupported language
- **WHEN** the device language is German
- **THEN** the interface is in English

### Requirement: Locale-aware formatting
Dates, weekday and month names, decimal numbers and plural forms SHALL follow the interface language.

#### Scenario: Russian plurals and decimals
- **WHEN** the interface is Russian
- **THEN** relative days use Russian plural forms and decimals use a comma
