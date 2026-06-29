# FishSignal

Prototype-state Flutter app for FishSignal, a pressure-aware and tide-aware fishing bite-window forecast.

## Run

```bash
flutter run
```

## Validate

```bash
dart format .
flutter analyze
flutter test
```

## Prototype Scope

Real in this prototype:

- Flutter iOS and Android app shell.
- Local first-run onboarding that collects water type, home mark, trip rhythm, and alert intent.
- Local saved spots with active/home/delete behavior, target species, mark notes, and per-spot Today signals.
- Bite score computed in Dart from fixture pressure, tide, wind and solunar drivers.
- Today screen, best-window detail, 7-day planner, spots, settings and paywall facade.
- Local session plan, exact saved window alerts, and copyable share-card preview.

Mocked or not connected:

- Weather, pressure, tide and solunar data are deterministic fixtures.
- Location, native notifications, native share sheets and purchases are facades.
- No Firebase, RevenueCat, AppStoreCopilot, AppRefer, Gleap, analytics, ads, store setup or provider credentials.
- Not a marine safety, navigation or catch-guarantee tool.
