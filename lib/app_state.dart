import 'package:flutter/material.dart';

import 'fixtures.dart';
import 'models.dart';
import 'score_engine.dart';

class FishColors {
  static const ink = Color(0xFF0B1A24);
  static const inkSoft = Color(0xFF12303F);
  static const inkLine = Color(0xFF1E3B4D);
  static const sea = Color(0xFF2E7D8C);
  static const seaBright = Color(0xFF4FB3C4);
  static const amber = Color(0xFFE8A33D);
  static const amberDim = Color(0xFFB67E2C);
  static const mist = Color(0xFFC9D8DF);
  static const mistDim = Color(0xFF7F97A2);
  static const go = Color(0xFF5BB98C);
  static const maybe = Color(0xFFE8A33D);
  static const wait = Color(0xFF7F97A2);

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
