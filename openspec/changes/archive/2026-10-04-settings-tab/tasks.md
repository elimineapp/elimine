# Tasks

## 1. Settings tab

- [x] 1.1 In `lib/app/router.dart`, move the `/settings` route from the top level into a `StatefulShellBranch` and order the branches `/settings`, `/`, `/analytics`; verify the app builds, starts on Home and `/settings` is declared only once
- [x] 1.2 In `lib/app/shell.dart`, add a `NavigationDestination` with `Icons.settings_outlined` / `Icons.settings` and the `settingsTitle` label and order the destinations to match the branches, and update the class comment from "two" to "three" tabs; verify the bar shows Settings, Home and Analytics in that order
- [x] 1.3 Add a widget test that pumps the app router and checks: the three destinations in order, the middle "Home" destination selected at start, tapping "Settings" shows the Settings screen with the navigation bar and without a back button, and switching to Home and back keeps Settings' scroll position; verify the test passes

## 2. Home header

- [x] 2.1 Remove the `settingsAction` `IconButton` from the Home app bar in `lib/features/home/home_screen.dart`, dropping the then-unused import if any; verify `flutter analyze` reports nothing
- [x] 2.2 Add a case to `test/home_screen_test.dart` that Home has no `settingsAction` key and no settings icon in its header; verify the test passes

## 3. Verification

- [x] 3.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 3.2 Manual check on a device or emulator, in English and Russian: the bar shows Settings · Home · Analytics ("Настройки · Главная · Аналитика") and the app opens on Home; Settings opens as a tab without a back arrow; export/import snackbars appear above the bar; Home's header shows only the name and date
