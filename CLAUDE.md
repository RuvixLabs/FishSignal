# FishSignal

## Overview
	FishSignal production project promoted from Prototype Foundry record proto-20260622-fishing-calendar-tide-times-676749.

## Company Boundary
- Company: Ruvix Labs
- Project directory: /Users/missioncontrol/Documents/Ruvix-Labs/FishSignal
- Do not borrow credentials, provider state, screenshots, or store assets from another company.

## Source Prototype
- Prototype ID: proto-20260622-fishing-calendar-tide-times-676749
- Source concept: Fishing Calendar & Tide Times
- App Store ID: 414676749 / GB
- Prototype artifacts: /Users/missioncontrol/.mission-control/prototypes/runs/20260622T135511Z-fishing-calendar-tide-times-414676749
- Handoff docs: docs/prototype-handoff/

## Tech Stack
- Framework: Flutter
- Platform: Flutter project for cross-platform iOS + Android by default. Platform-specific native modules/extensions/watch targets live inside the Flutter project unless Joe explicitly asks for a non-Flutter stack.

## Next Workflow
	Use the shared app-idea-to-production skill before production implementation.
Start from prototype state evidence, then deliberately add Firebase, RevenueCat, AppStoreCopilot, AppRefer, analytics, store assets, and release setup only when approved.

## Design System ("Golden Hour", Claude-Code-owned)
The UI direction is a soft, rounded, gradient-led "golden hour over water" look — approachable and modern, deliberately NOT a data dashboard. Owned in Flutter, no new dependencies.

- **Palette + gradients:** `lib/app_state.dart` → `FishColors`. Deep twilight base (`bgGradient`), warm golden-hour accents (`amber`/`gold`/`coral`), water teals (`sea`/`seaBright`).
  - `FishColors.heroGradient(verdict)` — the hero card gradient **is** the verdict: warm gold = Go, lagoon teal = Marginal, cool slate = Wait.
  - `FishColors.onHero(verdict)` — readable foreground colour over each hero gradient (dark ink on gold, white on teal/slate).
- **Surfaces:** `_Surface` is a frosted glass card (24px radius, faint white top-light gradient, hairline white border, soft drop shadow). All cards float over `_AppBackground` (the app-wide twilight gradient, applied in `HomeShell`, onboarding, window-detail, paywall).
- **Today screen (`TodayScreen`):** primary surface. Layout: `_TodayHeader` → `_BiteHero` → driver grid → bite curve → disclosure.
  - `_BiteHero` — the loud moment: verdict-gradient card with the tonal `_BiteDial`, the best window time, a friendly one-line read, and the primary **Open window** button + alert toggle.
  - `_BiteDial` / `_BiteDialPainter` — custom-painted 270° tonal score dial (reused on window detail + onboarding preview).
  - `_DriverGrid` / `_DriverTile` — 2×2 driver tiles (pressure/tide/wind/solunar) with icon, plain-language detail, and a strength bar driven by `DriverContribution.score01`.
  - `_BiteCurveCard` / `_BiteCurvePainter` — smooth filled area chart of the day's hourly bite score with the best-window band highlighted and the peak marked. This is the product mechanic made visible.
- **Theme:** `lib/main.dart` `_buildTheme()` — rounded 18px filled/outlined buttons, 54px min height, floating snackbars, M3 nav bar restyled in `HomeShell`.

### Design gotchas / invariants
- The widget test (`test/widget_test.dart`) asserts `Icons.speed_outlined` on Today — the Today nav destination must have **no `selectedIcon`** (it's the selected tab, so a selectedIcon would hide the outlined one). Keep the `'mock forecast'` chip and `'Open window'` label text intact.
- CustomPainter helper that returns `double` must return `0.0`, not `0` (a `0`/`double` ternary infers `num` and fails to compile).
- All alpha uses `Color.withValues(alpha:)` (not the deprecated `withOpacity`).
