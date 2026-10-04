# Proposal

## Why

Settings is reached through a small gear in the Home header, which is easy to miss and puts a rare, setup-only action on the screen that should hold only the daily path. A third bottom navigation destination makes Settings discoverable at a fixed place and leaves the Home header to the app name and date.

## What Changes

- The bottom navigation bar becomes Settings · Home · Analytics: "Settings" is added as the first destination, "Home" moves to the middle and "Analytics" to the right. The app still opens on Home.
- Settings becomes a tab: it shows the bottom navigation bar, has no back action and keeps its state (scroll position) while the user switches tabs, like the other tabs.
- The settings action is removed from the Home header. The header keeps the app name and the current date.
- Settings is no longer one of the screens that open above the tabs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `navigation`: the bottom navigation bar has three destinations in the order "Settings", "Home", "Analytics", and the app opens on the middle one, Home; Settings leaves the list of screens that open above the tabs.
- `home`: the header no longer has a settings action.

## Impact

- `lib/app/shell.dart`: a third `NavigationDestination` with the settings icon and the existing `settingsTitle` label.
- `lib/app/router.dart`: `/settings` moves from a top-level route into a shell branch, and the branches are reordered to `/settings`, `/`, `/analytics`.
- `lib/features/home/home_screen.dart`: the `settingsAction` button is removed from the app bar.
- Localization: no new strings; "Settings" / "Настройки" already exist as `settingsTitle`.
- Tests: a widget test for the three destinations and the Home header without the settings action.
- Specs that mention "the Settings screen" (analytics, data-backup, releases) stay valid: the screen and its content do not change.
