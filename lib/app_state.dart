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
  TripRhythm tripRhythm = TripRhythm.dawn;
  bool alertIntent = false;

  final List<Spot> spots = seedSpots();
  final List<SavedWindowAlert> savedAlerts = [];
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
    required TripRhythm tripRhythm,
    required bool alertIntent,
  }) {
    this.waterType = waterType;
    this.tripRhythm = tripRhythm;
    this.alertIntent = alertIntent;
    for (final s in spots) {
      s.isHomeMark = s.id == homeSpotId;
      if (s.id == homeSpotId) {
        s.waterType = waterType;
        s.alertEnabled = alertIntent;
      }
    }
    activeSpotId = homeSpotId;
    onboardingComplete = true;
    if (alertIntent) {
      final spot = activeSpot;
      if (spot != null) saveWindowAlert(spot, todayFor(spot), notify: false);
    }
    notifyListeners();
  }

  void setTripRhythm(TripRhythm rhythm) {
    tripRhythm = rhythm;
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
        if (!spot.alertEnabled) {
          savedAlerts.removeWhere((alert) => alert.spotId == id);
        }
        notifyListeners();
        return;
      }
    }
  }

  SavedWindowAlert? alertFor(String spotId, DayScore score) {
    final date = score.forecast.date;
    for (final alert in savedAlerts) {
      if (alert.spotId == spotId &&
          alert.date.year == date.year &&
          alert.date.month == date.month &&
          alert.date.day == date.day &&
          alert.startHour == score.bestWindow.startHour) {
        return alert;
      }
    }
    return null;
  }

  SavedWindowAlert saveWindowAlert(
    Spot spot,
    DayScore score, {
    bool notify = true,
  }) {
    savedAlerts.removeWhere((alert) => alert.id == _alertId(spot, score));
    final alert = SavedWindowAlert(
      spotId: spot.id,
      spotName: spot.name,
      date: score.forecast.date,
      startHour: score.bestWindow.startHour,
      endHour: score.bestWindow.endHour,
      score: score.rounded,
    );
    savedAlerts.add(alert);
    spot.alertEnabled = true;
    if (notify) notifyListeners();
    return alert;
  }

  bool toggleWindowAlert(Spot spot, DayScore score) {
    final existing = alertFor(spot.id, score);
    if (existing != null) {
      savedAlerts.removeWhere((alert) => alert.id == existing.id);
      spot.alertEnabled = savedAlerts.any((alert) => alert.spotId == spot.id);
      notifyListeners();
      return false;
    }
    saveWindowAlert(spot, score);
    return true;
  }

  void addSampleSpot() {
    final next = spots.length + 1;
    final template = _sampleTemplates[(next - 1) % _sampleTemplates.length];
    final spot = Spot(
      id: 'spot-new-$next',
      name: template.name,
      area: template.area,
      waterType: template.waterType,
      target: template.target,
      accessNote: template.accessNote,
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

  TripRecommendation recommendationFor(Spot spot) {
    final day = todayFor(spot);
    final rhythmWindow = tripRhythm.allDay
        ? day.bestWindow
        : engine.bestWindowWithin(
            day.hourScores,
            startHour: tripRhythm.startHour,
            endHour: tripRhythm.endHour,
          );
    return TripRecommendation(
      spot: spot,
      day: day,
      rhythm: tripRhythm,
      rhythmWindow: rhythmWindow,
    );
  }

  List<String> sessionChecklist(Spot spot, DayScore score) {
    final hour = score.hourScores.firstWhere(
      (h) => h.sample.hour == score.bestWindow.startHour,
      orElse: () => score.hourScores.first,
    );
    final topDriver = [...hour.contributions]
      ..sort((a, b) => b.points.compareTo(a.points));
    return [
      'Arrive by ${_hourLabel(score.bestWindow.startHour - 1)} to settle before the bite.',
      'Fish ${spot.target.toLowerCase()} at ${spot.name}.',
      topDriver.first.detail,
      hour.sample.windKph > 28
          ? 'Keep the plan short: wind is the main comfort risk.'
          : 'Pack for a ${hour.sample.windKph.round()} kph breeze.',
    ];
  }

  String shareCardFor(Spot spot, DayScore score) {
    final verdict = verdictFor(score.dayScore);
    return [
      'FishSignal: ${spot.name}',
      '${score.forecast.weekdayLabel} ${score.forecast.dateLabel}',
      'Best window: ${score.bestWindow.rangeLabel}',
      'Bite signal: ${score.rounded}/100 (${verdict.headline})',
      'Top target: ${spot.target}',
      'Planning aid only - no catch guarantee.',
    ].join('\n');
  }

  String _alertId(Spot spot, DayScore score) {
    final date = score.forecast.date;
    return '${spot.id}-${date.year}-${date.month}-${date.day}-${score.bestWindow.startHour}';
  }

  String _hourLabel(int hour) {
    final wrapped = hour < 0 ? hour + 24 : hour;
    final h = wrapped % 12 == 0 ? 12 : wrapped % 12;
    final suffix = wrapped < 12 ? 'AM' : 'PM';
    return '$h $suffix';
  }
}

class TripRecommendation {
  const TripRecommendation({
    required this.spot,
    required this.day,
    required this.rhythm,
    required this.rhythmWindow,
  });

  final Spot spot;
  final DayScore day;
  final TripRhythm rhythm;
  final BiteWindow rhythmWindow;

  bool get bestFitsRhythm =>
      rhythm.allDay ||
      (day.bestWindow.startHour >= rhythm.startHour &&
          day.bestWindow.endHour <= rhythm.endHour);

  String get rhythmLine {
    if (rhythm.allDay) return 'You can follow the best water today.';
    if (bestFitsRhythm) {
      return 'This fits your ${rhythm.label.toLowerCase()} rhythm.';
    }
    return 'Best in your ${rhythm.label.toLowerCase()} slot: ${rhythmWindow.rangeLabel} · ${rhythmWindow.rounded}/100';
  }
}

class _SampleSpotTemplate {
  const _SampleSpotTemplate({
    required this.name,
    required this.area,
    required this.waterType,
    required this.target,
    required this.accessNote,
  });

  final String name;
  final String area;
  final WaterType waterType;
  final String target;
  final String accessNote;
}

const _sampleTemplates = [
  _SampleSpotTemplate(
    name: 'Brighton West Pier',
    area: 'Brighton, Sussex',
    waterType: WaterType.saltShore,
    target: 'Bass and smooth-hound',
    accessNote: 'Urban shore mark with moving-water windows',
  ),
  _SampleSpotTemplate(
    name: 'Avon evening bend',
    area: 'Salisbury, Wiltshire',
    waterType: WaterType.freshwater,
    target: 'Barbel and chub',
    accessNote: 'Pressure-led river session',
  ),
  _SampleSpotTemplate(
    name: 'Solent drift line',
    area: 'Portsmouth, Hampshire',
    waterType: WaterType.saltBoat,
    target: 'Bream and bass',
    accessNote: 'Boat mark where tide run decides the drift',
  ),
];

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
