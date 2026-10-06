# Design

## Context

- Home is one `CustomScrollView` in `lib/features/home/home_screen.dart`: the substance list, "New substance", the "Recent" list from `recentIntakesProvider` (`watchRecentIntakes(limit: 10)`), then the archive row. It has no `ScrollController`.
- The last intake label comes from `ElimineFormat.lastIntake` → `relativeDay` in `lib/core/l10n/format.dart`. It works on calendar days with `days ~/ 30` and `days ~/ 365`, and has no notion of hours. It is used by the Home tile and the substance screen header (which takes an injectable `clock`).
- Labels re-render only when a provider emits. Nothing ticks.
- The bottom navigation (`lib/app/shell.dart`) handles reselect with `goBranch(i, initialLocation: true)`. That resets the branch's route stack but does not scroll.
- `watchArchivedSubstances` returns `(substance, intakes count)`. `watchSubstancesWithLast` already finds the latest intake with a correlated subquery.
- Reduced motion is read through `Motion.reducedOf(context)`.

## Goals / Non-Goals

**Goals:**
- Page the History feed without a visible loading state or jumps.
- One elapsed-time formatter used everywhere a last intake is shown.
- Keep the change free of new dependencies and database migrations.

**Non-Goals:**
- A data-level sliding window that drops rows that have scrolled away.
- Opening an archived substance's screen from the archive.
- A draggable scrollbar or jumping to a date in History.
- Changing absolute times in lists ("Today, 14:35"). They stay as they are.

## Decisions

### History paging: a growing limit on the existing stream
`historyLimitProvider` (a `Notifier<int>`) starts at 50. The history provider watches it and calls `watchRecentIntakes(limit:)`. While the list builds an item within 10 of its end, and the list length equals the limit (so more rows may exist), the limit grows by 50. The lazy `SliverList.builder` already bounds what is built to the viewport plus the cache extent.
- When the limit grows, the provider rebuilds and passes through `AsyncLoading`, which keeps the previous value. Home must render from `.value` and fall back to the empty or error states only when there is no value. The current `switch` on `AsyncData` would blank the list for a frame and lose the scroll offset.
- The limit lives as long as the Home tab. It is not reset when the user scrolls back up: re-querying a few hundred rows on each change is cheap.
- Alternatives: a "Show more" button (one tap per page, rejected in discussion); keyset pagination with page-by-page merging (more code, no benefit at this data size); loading everything (unbounded on every DB change, avoidable for no cost).

### Archive row position
Move the existing `archiveEntry` `ListTile` into the substances group, right after `_NewSubstanceTile`, with the same quiet look (outlined icon, chevron, no tint). The `Key('archiveEntry')` and the route stay.

### Scroll to top: one controller, two triggers
`HomeScreen` becomes a `ConsumerStatefulWidget` that owns a `ScrollController` for its `CustomScrollView`.
- **Back to top button**: a `NotificationListener<UserScrollNotification>` records the last direction. The button shows while `offset > 2 * viewportDimension` and the direction is `ScrollDirection.forward` (scrolling up). It is a small `FloatingActionButton` with an upward arrow and the tooltip "Back to top", shown with a scale and fade (`AnimatedScale` with `AnimatedOpacity`, or only the fade under reduced motion).
- **Reselecting Home**: `homeScrollToTopProvider` is a `Notifier<int>` counter that the shell bumps when the Home destination is tapped while already selected. `HomeScreen` listens to it with `ref.listen` and scrolls. The existing `goBranch(initialLocation: true)` call stays for the other tabs.
- Scrolling: `animateTo(0)` with `Motion.standard` and a duration that grows with distance, capped at about 600 ms. Under `Motion.reducedOf` it uses `jumpTo(0)` instead.
- Alternatives: `PrimaryScrollController` (the shell's Scaffold does not expose it per branch; the iOS status-bar tap is a separate concern); exposing the `ScrollController` itself through a provider (couples lifetimes; an event counter is simpler).

### Elapsed time formatter
`relativeDay(DateTime day, DateTime now)` is replaced by `elapsed(Intake intake, DateTime now)`, built on a pure function that returns the largest step and its parts:
- Minutes and hours: `now.difference(intake.takenAt)` in absolute time, so time zone changes do not distort them.
- Days and above: calendar arithmetic on the intake's wall time (`intakeWallTime`) against `now`'s local wall time. Add whole months to the intake's date and time of day, clamping the day to the target month's length, until the next month would pass `now`; whole years = months ~/ 12. The remaining days are counted as whole days from the clamped anchor's time of day.
- Steps, chosen by the elapsed duration and the month count: < 1 min, < 60 min, < 24 h, < 7 days, < 1 month, < 12 months, < 120 months, else years.
- Zero second unit: the label falls back to the single-unit string ("3 days ago", "4 months ago", "1 year ago", "5 h ago").

### Strings
Compound strings are separate ARB messages with two plural placeholders rather than concatenated fragments, so Russian word order and plural forms stay in the translation:

| Step | English | Russian |
|---|---|---|
| < 1 min | just now | только что |
| minutes | 12 min ago | 12 мин назад |
| hours (+ min) | 5 h 12 min ago | 5 ч 12 мин назад |
| days + hours | 3 d 5 h ago | 3 дн. 5 ч назад |
| days alone | 3 days ago | 3 дня назад |
| months + days | 4 mo 12 d ago | 4 мес. 12 дн. назад |
| months alone | 4 months ago | 4 мес. назад |
| years + months | 1 year 11 mo ago | 1 год 11 мес. назад |
| years alone | 12 years ago | 12 лет назад |

The years-and-months message pluralizes the year word ("1 год", "2 года", "5 лет", "1 year", "2 years"). `relativeToday` and `relativeYesterday` are removed if nothing else uses them.

### Minute tick
`minuteTickProvider` is a `StreamProvider<DateTime>` that emits the current time at once and then at each minute boundary. A `Timer` is aligned to the next minute and rescheduled after each tick; it is cancelled in `ref.onDispose`. The Home tile and the archive screen `ref.watch` it to rebuild, and they read the time from `clockProvider` (a `Provider<DateTime Function()>`, `DateTime.now` by default). Tests override that provider to move time forward together with the fake timer. The substance screen header also watches the tick but keeps its injected `clock`.
- Alternative: a `Ticker`/`setState` per widget. That means more places to manage, and the archive screen and Home would each need their own.

### Archive query
`watchArchivedSubstances` gains the same correlated "latest intake" subquery as `watchSubstancesWithLast` and returns `({Substance substance, int intakes, Intake? last})`. The archive subtitle is `[lastIntake, entriesCount].join(' · ')` when there is a last intake, otherwise just `entriesCount` ("No entries").

## Risks / Trade-offs

- [Periodic timer left pending in widget tests fails them] → The timer is cancelled on provider dispose. Tests already end by pumping an empty widget, which disposes the scope. If that is not enough, tests override `minuteTickProvider` with a single-value stream.
- [Rebuilding Home every minute] → Only widgets that watch the tick rebuild. The history list does not watch it, because its absolute times do not need it.
- [Rendering from `.value` hides a real loading state on first open] → On first load there is no value yet, so the existing loading path is still shown.
- [Swipe-to-delete and the edit sheet in a paged list] → `IntakeTile` already keys `Dismissible` by intake id, and deleting shrinks the stream result without changing the limit.
- [Behavior change: "today" and "yesterday" disappear from tiles] → This was agreed. The absolute "Today, 14:35" in lists is unchanged.
- [Calendar math at DST edges] → Day counts use wall time, so a DST shift moves at most an hour within the day step and never changes the month or year count.
