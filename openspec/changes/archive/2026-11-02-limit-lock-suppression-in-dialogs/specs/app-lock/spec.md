# Spec Delta

## MODIFIED Requirements

### Requirement: When the app locks
While the lock is on, the app SHALL be locked on every cold start. After the app leaves the foreground, it SHALL lock when it comes back if it spent at least the "Lock after" time in the background. "Lock after" SHALL offer "Immediately", "1 minute" (default), "5 minutes" and "15 minutes". Time in a system dialog the app opens itself SHALL NOT count as leaving the foreground unless it lasts at least the "Lock after" time or 5 minutes, whichever is longer; the app SHALL then lock when the dialog closes.

#### Scenario: Cold start
- **WHEN** the lock is on and the app starts after being closed
- **THEN** its first frame is the lock screen, without first showing Home

#### Scenario: Quick switch
- **WHEN** "Lock after" is "1 minute" and the user switches to another app for 20 seconds and back
- **THEN** the app is not locked

#### Scenario: Longer absence
- **WHEN** "Lock after" is "1 minute" and the user returns after 2 minutes in another app
- **THEN** the lock screen is shown

#### Scenario: Immediately
- **WHEN** "Lock after" is "Immediately" and the user switches to another app for 2 seconds and back
- **THEN** the lock screen is shown

#### Scenario: Screen turned off
- **WHEN** "Lock after" is "1 minute" and the screen is turned off with the app open for 5 minutes
- **THEN** the lock screen is shown when the user turns the screen on and unlocks the phone

#### Scenario: Exporting a backup
- **WHEN** "Lock after" is "Immediately" and the user taps "Export" and spends 3 minutes in the system "Save as" dialog
- **THEN** the app is not locked when the dialog closes, and the export snackbar is shown

#### Scenario: Leaving from a system dialog
- **WHEN** "Lock after" is "Immediately" and the user taps "Export", goes home from the system "Save as" dialog and comes back to it after an hour
- **THEN** the lock screen is shown when the dialog closes

#### Scenario: Long dialog with a long "Lock after"
- **WHEN** "Lock after" is "15 minutes" and the user spends 10 minutes in the system "Save as" dialog
- **THEN** the app is not locked when the dialog closes
