import 'package:flutter/material.dart';

import 'fixtures.dart';
import 'models.dart';
import 'score_engine.dart';

/// FishSignal visual language: soft "golden-hour over water" palette.
///
/// The whole app reads as a calm twilight gradient; the only loud colour is the
/// hero card, whose gradient *is* the verdict — warm gold means go now, lagoon
/// teal means marginal, cool slate means wait. Surfaces are frosted glass with
/// big radii and soft shadows, never hairline dashboard boxes.
class FishColors {
  // Deep twilight base + raised surface fallbacks.
  static const ink = Color(0xFF0A1B29);
  static const inkSoft = Color(0xFF14334A);
  static const inkLine = Color(0xFF274A60);

  // Brand water tones.
  static const sea = Color(0xFF2F8DA0);
  static const seaBright = Color(0xFF63C7D6);

  // Warm golden-hour accents.
  static const amber = Color(0xFFFFB85C);
  static const amberDim = Color(0xFFC78A3E);
  static const coral = Color(0xFFFF8C66);
  static const gold = Color(0xFFFFD27A);

  // Text.
  static const mist = Color(0xFFE9F2F6);
  static const mistDim = Color(0xFF9DB6C3);

  // Verdict tones (used for small accents / week ranking).
  static const go = Color(0xFF5FD49B);
  static const maybe = Color(0xFFFFB85C);
  static const wait = Color(0xFF8AA6B7);

  // App background mesh (top -> bottom).
  static const List<Color> bgGradient = [
    Color(0xFF0A1B29),
    Color(0xFF112E40),
    Color(0xFF0B2333),
  ];

  static const shadow = Color(0x66000813);

  static Color forVerdict(BiteVerdict v) {
    switch (v) {
      case BiteVerdict.go:
        return go;
      case BiteVerdict.maybe:
        return maybe;
      case BiteVerdict.wait:
        return wait;
    }
  }

  /// The soft hero gradient that carries the verdict at a glance.
  static List<Color> heroGradient(BiteVerdict v) {
    switch (v) {
      case BiteVerdict.go:
        return const [Color(0xFFFFA85A), Color(0xFFFFC76C), Color(0xFFFFB347)];
      case BiteVerdict.maybe:
        return const [Color(0xFF2E9FB3), Color(0xFF5BC9C3), Color(0xFF3FB0AE)];
      case BiteVerdict.wait:
        return const [Color(0xFF3C5A70), Color(0xFF5C7F95), Color(0xFF45657C)];
    }
  }

  /// Readable foreground colour to lay over the hero gradient.
  static Color onHero(BiteVerdict v) =>
      v == BiteVerdict.go ? const Color(0xFF0A2230) : Colors.white;
}

class AppState extends ChangeNotifier {
  AppState();

  final ScoreEngine engine = const ScoreEngine();
  final FixtureForecaster forecaster = const FixtureForecaster();

  bool onboardingComplete = false;
  WaterType waterType = WaterType.saltShore;
  bool alertIntent = false;

  final List<Spot> spots = seedSpots();
  String? activeSpotId;
  final DateTime anchor = DateTime(2026, 6, 22);

  Spot? get activeSpot {
    if (spots.isEmpty) return null;
    final id = activeSpotId;
    if (id == null) return spots.first;
    return spots.firstWhere((s) => s.id == id, orElse: () => spots.first);
  }

  void completeOnboarding({
    required WaterType waterType,
    required String homeSpotId,
    required bool alertIntent,
  }) {
    this.waterType = waterType;
    this.alertIntent = alertIntent;
    for (final s in spots) {
      s.isHomeMark = s.id == homeSpotId;
    }
    activeSpotId = homeSpotId;
    onboardingComplete = true;
    notifyListeners();
  }

  void setActiveSpot(String id) {
    activeSpotId = id;
    notifyListeners();
  }

  void deleteSpot(String id) {
    Spot? target;
    for (final spot in spots) {
      if (spot.id == id) {
        target = spot;
        break;
      }
    }
    if (target == null) return;
    final wasActive = id == activeSpotId;
    final wasHome = target.isHomeMark;
    spots.removeWhere((s) => s.id == id);
    if (spots.isEmpty) {
      activeSpotId = null;
    } else {
      if (wasHome) spots.first.isHomeMark = true;
      if (wasActive) activeSpotId = spots.first.id;
    }
    notifyListeners();
  }

  void makeHomeMark(String id) {
    for (final s in spots) {
      s.isHomeMark = s.id == id;
    }
    notifyListeners();
  }

  void toggleAlert(String id) {
    for (final spot in spots) {
      if (spot.id == id) {
        spot.alertEnabled = !spot.alertEnabled;
        notifyListeners();
        return;
      }
    }
  }

  void addSampleSpot() {
    final next = spots.length + 1;
    final spot = Spot(
      id: 'spot-new-$next',
      name: 'New mark $next',
      area: 'Prototype fixture',
      waterType: waterType,
    );
    spots.add(spot);
    activeSpotId = spot.id;
    notifyListeners();
  }

  List<DayScore> weekFor(Spot spot) {
    final week = forecaster.week(spot, anchor: anchor);
    return engine.scoreWeek(week, tideMatters: spot.waterType.tideMatters);
  }

  DayScore todayFor(Spot spot) => weekFor(spot).first;
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
