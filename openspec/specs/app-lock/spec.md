# app-lock Specification

## Purpose
An optional lock that keeps the app's content hidden from anyone holding the unlocked phone until the user enters their own PIN or passes a biometric check.

## Requirements

### Requirement: Security section
The Settings screen SHALL have a "Security" section between "General" and "Backup". It SHALL hold an "App lock" switch, off by default. While the switch is on, the section SHALL also show "Change PIN", "Lock after" and, when the device has a strong biometric enrolled, a "Biometric unlock" switch. While it is off, the section SHALL show only "App lock".

#### Scenario: Default state
- **WHEN** the user opens Settings for the first time
- **THEN** a "Security" section between "General" and "Backup" shows the "App lock" switch turned off and no other rows

#### Scenario: Lock on
- **WHEN** the app lock is on and the device has a fingerprint enrolled
- **THEN** the "Security" section shows "App lock", "Biometric unlock", "Lock after" and "Change PIN"

#### Scenario: No biometrics on the device
- **WHEN** the app lock is on and the device has no fingerprint or other strong biometric enrolled
- **THEN** the "Biometric unlock" row is not shown

### Requirement: Turning the lock on
Turning "App lock" on SHALL open a screen to choose a PIN of 4 to 8 digits, which the user SHALL enter twice. The screen SHALL warn that a forgotten PIN can only be reset by erasing all data, and suggest exporting a backup first. The lock SHALL be on only after both entries match; going back or a mismatch SHALL leave it off. The app SHALL NOT lock right after the lock is turned on.

#### Scenario: Choosing a PIN
- **WHEN** the user turns "App lock" on, enters "2468", taps "Next", enters "2468" again and taps "Done"
- **THEN** the app lock is on, Settings is shown again, and the "App lock" switch is on

#### Scenario: Entries differ
- **WHEN** the user enters "2468" and then "2469" as the confirmation
- **THEN** the screen says the PINs do not match and asks for a new PIN from the start
- **AND** the app lock stays off

#### Scenario: Too short
- **WHEN** the user has entered 3 digits
- **THEN** "Next" is disabled

#### Scenario: Cancelled
- **WHEN** the user goes back from the PIN screen before confirming
- **THEN** the app lock stays off

#### Scenario: Warning about a forgotten PIN
- **WHEN** the PIN screen opens to turn the lock on
- **THEN** it says that a forgotten PIN can only be reset by erasing all data, and suggests exporting a backup first

### Requirement: Turning the lock off
Turning "App lock" off SHALL ask for the current PIN, or a biometric check when "Biometric unlock" is on. After success the lock SHALL be off and the PIN, the biometric choice and the "Lock after" choice SHALL be forgotten.

#### Scenario: Turning off with the PIN
- **WHEN** the user turns "App lock" off and enters the right PIN
- **THEN** the app lock is off and the app no longer asks for a PIN at start

#### Scenario: Wrong PIN
- **WHEN** the user turns "App lock" off and enters a wrong PIN
- **THEN** the app lock stays on

#### Scenario: Turning on again
- **WHEN** the lock was turned off and the user turns it on again
- **THEN** the user chooses a new PIN, and "Lock after" is back at "1 minute"

### Requirement: Changing the PIN
"Change PIN" SHALL ask for the current PIN, then for a new PIN of 4 to 8 digits entered twice. The old PIN SHALL keep working until the new one is confirmed.

#### Scenario: Changing
- **WHEN** the user taps "Change PIN", enters the current PIN "2468", then "1357" twice
- **THEN** the lock screen accepts "1357" and rejects "2468" from then on

#### Scenario: Wrong current PIN
- **WHEN** the user taps "Change PIN" and enters a wrong current PIN
- **THEN** the user cannot choose a new PIN and "2468" keeps working

### Requirement: Lock screen
While the app is locked, it SHALL show only the lock screen: the app icon, "Enter PIN", one dot per entered digit, a numeric keypad with a delete key, and "Forgot PIN?". The entered PIN SHALL be checked as soon as it has as many digits as the stored one. The right PIN SHALL show the app as it was before locking: the same tab, screen and scroll position. System back on the lock screen SHALL leave the app without unlocking it.

#### Scenario: Unlocking
- **WHEN** the app is locked on the Analytics tab with the "Year" range selected and the user enters the right PIN
- **THEN** the lock screen disappears and Analytics shows the "Year" range

#### Scenario: Wrong PIN
- **WHEN** the user enters a wrong PIN
- **THEN** the dots shake, the screen says "Wrong PIN", and the dots are cleared for a new attempt

#### Scenario: Nothing behind the lock
- **WHEN** the app is locked
- **THEN** no substance name, intake or chart is visible or announced by a screen reader, including in dialogs and sheets that were open

#### Scenario: Back on the lock screen
- **WHEN** the user presses system back on the lock screen
- **THEN** the app goes to the background and is still locked when reopened

### Requirement: Biometric unlock
"Biometric unlock" SHALL be off when the lock is turned on. Turning it on SHALL require one successful biometric check. While it is on, the lock screen SHALL show the system biometric prompt as soon as it appears, and a key on the keypad SHALL show it again. Cancelling or failing the prompt SHALL leave the PIN keypad usable.

#### Scenario: Turning on
- **WHEN** the user turns "Biometric unlock" on and touches an enrolled finger to the sensor
- **THEN** the switch stays on

#### Scenario: Check failed while turning on
- **WHEN** the user turns "Biometric unlock" on and cancels the system prompt
- **THEN** the switch stays off

#### Scenario: Opening with a fingerprint
- **WHEN** biometric unlock is on and the user opens the locked app and touches the sensor
- **THEN** the app unlocks without any tap on the screen

#### Scenario: Falling back to the PIN
- **WHEN** the user cancels the biometric prompt on the lock screen
- **THEN** the PIN keypad stays on screen and the right PIN unlocks the app

#### Scenario: Biometrics removed from the device
- **WHEN** biometric unlock is on and the user removes every enrolled fingerprint in the system settings
- **THEN** the lock screen shows only the PIN keypad and the PIN still unlocks the app

### Requirement: When the app locks
While the lock is on, the app SHALL be locked on every cold start. After the app leaves the foreground, it SHALL lock when it comes back if it spent at least the "Lock after" time in the background. "Lock after" SHALL offer "Immediately", "1 minute" (default), "5 minutes" and "15 minutes". System dialogs the app opens itself SHALL NOT count as leaving the foreground.

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

### Requirement: Wrong PIN throttling
After 5 wrong PINs in a row, the lock screen SHALL refuse input for 30 seconds, showing the time left, and each further wrong PIN SHALL double the wait, up to 1 hour. The count SHALL be kept across restarts and reset by a successful unlock. The same SHALL apply wherever the app asks for the current PIN.

#### Scenario: Fifth wrong PIN
- **WHEN** the user enters a wrong PIN for the fifth time in a row
- **THEN** the keypad is disabled for 30 seconds with a countdown

#### Scenario: Wait grows
- **WHEN** the wait has passed and the user enters a wrong PIN again
- **THEN** the keypad is disabled for 1 minute

#### Scenario: Restart does not reset
- **WHEN** the keypad is disabled and the user closes and reopens the app
- **THEN** the keypad is still disabled for the remaining time

#### Scenario: Biometrics while waiting
- **WHEN** the keypad is disabled and biometric unlock is on
- **THEN** a successful biometric check unlocks the app and resets the count

### Requirement: Forgotten PIN
"Forgot PIN?" on the lock screen SHALL explain that the PIN cannot be recovered and offer to erase all data. Only after the user confirms as the erase confirmation requires SHALL the app erase all substances, doses and intakes, turn the lock off and open on an empty Home. Language, theme and first day of the week SHALL be kept. Erased data SHALL NOT be recoverable from the app's database files.

#### Scenario: Erasing
- **WHEN** the user taps "Forgot PIN?", types "ERASE ALL" and taps "Erase all"
- **THEN** the app opens on Home without substances, and the "App lock" switch in Settings is off

#### Scenario: Changing one's mind
- **WHEN** the user taps "Forgot PIN?" and then "Cancel"
- **THEN** nothing is erased and the lock screen is shown again

#### Scenario: Nothing left in the files
- **WHEN** data with a substance named "Zebra-test" is erased after a forgotten PIN
- **THEN** the app's database files no longer contain "Zebra-test"

#### Scenario: Restoring from a backup
- **WHEN** the user erased all data and then imports a backup exported earlier
- **THEN** the substances and intakes from the backup are back

### Requirement: Erase confirmation
The "Forgot PIN?" dialog SHALL have a text field, "Cancel" and "Erase all". "Erase all" SHALL stay disabled until the field holds the confirmation phrase of the interface language: "ERASE ALL" in English, "ОЧИСТИТЬ ВСЁ" in Russian. The check SHALL ignore letter case, spaces at the ends and extra spaces between the words, and SHALL treat "е" as "ё".

#### Scenario: Empty field
- **WHEN** the "Forgot PIN?" dialog opens
- **THEN** "Erase all" is disabled

#### Scenario: Wrong phrase
- **WHEN** the user types "ERASE" in the English interface
- **THEN** "Erase all" stays disabled

#### Scenario: Russian, typed casually
- **WHEN** the interface is in Russian and the user types " очистить  все"
- **THEN** "Очистить всё" becomes enabled

#### Scenario: Phrase of the other language
- **WHEN** the interface is in English and the user types "ОЧИСТИТЬ ВСЁ"
- **THEN** "Erase all" stays disabled

### Requirement: Hidden in recent apps
While the lock is on, once the app has left the screen, its card in the system's list of recent apps SHALL NOT show its content, on Android 13 and later. Opening the list from inside the unlocked app may show the app live, as it was on screen. Screenshots and screen recording inside the app SHALL stay allowed. Turning the lock off SHALL show the preview again.

#### Scenario: Recent apps
- **WHEN** the lock is on, the app shows Home, the user goes to the home screen and then opens the recent apps list on Android 14
- **THEN** the app's card shows no substance names or intakes

#### Scenario: Recent apps while locked
- **WHEN** the app is locked and the user opens the recent apps list
- **THEN** the app's card shows no substance names or intakes

#### Scenario: Screenshot
- **WHEN** the lock is on and the unlocked app shows Home
- **THEN** a system screenshot captures Home as usual

### Requirement: Lock settings are kept
The lock state, the PIN, the biometric choice and the "Lock after" choice SHALL be kept on the device across restarts. They SHALL NOT be part of backup files, and importing a backup SHALL NOT change them. The PIN SHALL NOT be stored in a form from which it can be read back directly.

#### Scenario: Not in backups
- **WHEN** the lock is on and the user exports a backup
- **THEN** the backup file contains neither the PIN nor any lock setting

#### Scenario: Importing on a locked app
- **WHEN** the lock is on with PIN "2468" and the user imports a backup made on another phone
- **THEN** the lock stays on and "2468" still unlocks the app
