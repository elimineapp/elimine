# Proposal

## Why

Intake history is sensitive, and a phone is often handed to someone else or left unlocked. Today anyone holding the unlocked phone can open Elimine and read everything. Users need an optional lock that keeps the app's content hidden until they enter their own PIN or touch the fingerprint sensor.

## What Changes

- A new "Security" section on the Settings screen with an "App lock" switch, off by default. Turning it on asks the user to choose a PIN of 4 to 8 digits and enter it twice. Turning it off asks for the PIN.
- While the lock is on, the app opens on a lock screen with a numeric keypad. The rest of the app appears only after the right PIN or a successful biometric check, and the user lands where they left off.
- "Biometric unlock" switch, shown when the device has a fingerprint or another strong biometric enrolled. When on, the lock screen shows the system biometric prompt at once, so unlocking takes a touch of the sensor. The PIN always works too.
- "Lock after" row with "Immediately", "1 minute" (default), "5 minutes" and "15 minutes": how long the app may stay in the background before it locks again. A cold start always locks. System dialogs the app opens itself (saving or opening a backup file, the biometric prompt) do not count as leaving the app.
- "Change PIN" row, which asks for the current PIN first.
- Wrong PINs are throttled: after 5 wrong entries in a row, each further attempt waits, with the wait growing and kept across restarts.
- "Forgot PIN?" on the lock screen offers, after the user types a confirmation phrase ("ERASE ALL", in Russian "ОЧИСТИТЬ ВСЁ"), to erase all substances and intakes and turn the lock off. There is no other way to recover a forgotten PIN, since nothing leaves the device. The PIN setup screen warns about this and suggests exporting a backup first.
- While the lock is on, the app's preview in the system's recent apps is blank (Android 13 and later). Screenshots stay allowed.
- Lock settings are kept on the device and are not part of backup files.
- Not included: encrypting the database, a lock for the planned home-screen widget, alphanumeric passwords, and a lock that applies only to some screens.

## Capabilities

### New Capabilities

- `app-lock`: the optional PIN and biometric lock: turning it on and off, the lock screen, when the app locks, wrong-PIN throttling, erasing data after a forgotten PIN, and hiding the app in recent apps.

### Modified Capabilities

- `local-data`: "Recoverable deletion" gains a second deliberate exception, erasing all data from the lock screen after a confirmation.

## Impact

- New dependencies: `local_auth` (system biometric prompt, built on AndroidX Biometric, no Google Play services) and `crypto` (salted PIN hashing). Both are open source and build from source, as F-Droid requires.
- Android: `MainActivity` becomes a `FlutterFragmentActivity`, which `local_auth` needs, and gains a small method channel to hide the recent apps preview. The `USE_BIOMETRIC` permission comes from the plugin's manifest.
- App shell: a lock layer above the router, so it covers every route and dialog. `main` reads the lock state before the first frame, so locked content never flashes.
- Settings service and screen: new keys in the existing `settings` table and a new section. No schema migration.
- New lock screen and PIN entry screens with English and Russian strings.
- Backup service: a new "erase everything" operation that relies on the existing `secure_delete` pragma.
- No change to the backup format: the `settings` table is already left out of backups.
