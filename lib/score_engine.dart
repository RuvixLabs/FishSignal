// FishSignal bite-score engine.
//
// This is the heart of the product wedge: a single, honest bite score computed
// from named drivers (pressure trend, tide movement, wind, solunar) — NOT a
// hardcoded number. The source app's top complaint was "it's just a solunar
// calendar and ignores pressure/weather", so pressure and tide carry real
// weight here and the breakdown is exposed to the UI for plain-language reasons.
//
// Pure Dart, no Flutter imports — fully unit-testable.

import 'dart:math' as math;

import 'models.dart';

/// The contribution of one driver to an hour's bite score.
class DriverContribution {
  const DriverContribution({
    required this.label,
    required this.detail,
    required this.score01,
    required this.weight,
  });

  /// Short driver name, e.g. "Pressure".
  final String label;

  /// Plain-angler sentence, e.g. "Falling pressure — fish feed ahead of weather".
  final String detail;

  /// Normalised 0..1 quality for this driver this hour.
  final double score01;

  /// How much this driver counts toward the final score (0..1, weights sum ~1).
  final double weight;

  /// Points this driver added to the 0..100 score.
  double get points => score01 * weight * 100;
}

/// The full result of scoring a single hour.
class HourScore {
  const HourScore({
    required this.sample,
    required this.score,
    required this.contributions,
  });

  final HourSample sample;

  /// 0..100 bite score.
  final double score;

  final List<DriverContribution> contributions;

  int get rounded => score.round();
}

/// A contiguous best window inside a day.
class BiteWindow {
  const BiteWindow({
    required this.startHour,
    required this.endHour,
    required this.score,
  });

  /// Inclusive start hour, 0..23.
  final int startHour;

  /// Exclusive end hour (start + length).
  final int endHour;

  /// Average 0..100 score across the window.
  final double score;

  int get rounded => score.round();

  String _fmt(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 || hour == 24 ? 'AM' : 'PM';
    // 24 wraps to 12 AM next day; clamp display to keep it simple.
    final hh = hour == 24 ? 12 : h;
    return '$hh ${hour == 24 ? 'AM' : suffix}';
  }

  String get rangeLabel => '${_fmt(startHour)} – ${_fmt(endHour)}';
}

/// A scored day: every hour scored, plus the single best N-hour window.
class DayScore {
  const DayScore({
    required this.forecast,
    required this.hourScores,
    required this.bestWindow,
    required this.dayScore,
  });

  final DayForecast forecast;
  final List<HourScore> hourScores;
  final BiteWindow bestWindow;

  /// Headline 0..100 for the day (equals the best-window average).
  final double dayScore;

  int get rounded => dayScore.round();
}

/// Qualitative bands used across the UI. Honest framing — never "you will catch".
enum BiteVerdict {
  go('Go', 'Conditions line up — worth the trip'),
  maybe('Marginal', 'Fishable, but pick your window'),
  wait('Wait', 'Better windows are coming');

  const BiteVerdict(this.headline, this.advice);

  final String headline;
  final String advice;
}

BiteVerdict verdictFor(double score) {
  if (score >= 65) return BiteVerdict.go;
  if (score >= 45) return BiteVerdict.maybe;
  return BiteVerdict.wait;
}

/// The scoring engine. Weights are tuned so pressure + tide dominate, which is
/// the differentiator vs a pure solunar calendar.
class ScoreEngine {
  const ScoreEngine();

  // Weights for tidal water. They sum to 1.0.
  static const double _wPressure = 0.32;
  static const double _wTide = 0.30;
  static const double _wSolunar = 0.23;
  static const double _wWind = 0.15;

  /// Default best-window length in hours. The promise is "your best two hours".
  static const int windowLength = 2;

  double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

  /// Falling pressure scores high; sharply rising scores low.
  /// trend is hPa over 3h. -3 or steeper => 1.0, +3 or steeper => ~0.0.
  double pressureScore(double trend3h) {
    // Map [-4 .. +4] hPa onto [1 .. 0], steady (0) lands at ~0.5.
    final v = 0.5 - (trend3h / 8.0);
    return _clamp01(v);
  }

  String pressureDetail(double trend3h) {
    if (trend3h <= -2.0) {
      return 'Pressure falling fast — fish often feed ahead of weather';
    }
    if (trend3h < -0.4) return 'Pressure easing off — a positive sign';
    if (trend3h <= 0.4) return 'Pressure steady — neutral';
    if (trend3h < 2.0) return 'Pressure rising — fish can go off the feed';
    return 'Pressure climbing fast — typically a tougher bite';
  }

  /// Moving water scores high; slack water scores low.
  double tideScore(double movement, {required bool tideMatters}) {
    if (!tideMatters) return 0.5; // neutral on freshwater
    return _clamp01(movement);
  }

  String tideDetail(
    TideState state,
    double movement, {
    required bool tideMatters,
  }) {
    if (!tideMatters) return 'Inland water — tide not a factor here';
    if (movement >= 0.7) {
      return '${state.label} — strong run of water moving bait';
    }
    if (movement >= 0.35) return '${state.label} — usable flow';
    return '${state.label} — slack water, bait sits still';
  }

  /// Light-to-moderate wind scores best. Flat calm and gales both score lower.
  double windScore(double kph) {
    // Ideal band ~8..22 kph. Penalise calm (<5) and strong (>32) winds.
    if (kph <= 0) return 0.45;
    if (kph < 8) return 0.45 + (kph / 8.0) * 0.45; // ramps 0.45 -> 0.90
    if (kph <= 22) return 1.0;
    if (kph <= 40) {
      final over = (kph - 22) / 18.0; // 0..1 across 22..40
      return _clamp01(1.0 - over * 0.85);
    }
    return 0.1;
  }

  String windDetail(double kph) {
    if (kph < 5) return 'Flat calm — a light ripple usually fishes better';
    if (kph <= 22) return 'A fishable breeze putting some chop on the water';
    if (kph <= 34) return 'Getting fresh — workable but harder going';
    return 'Too much wind for comfortable, safe fishing';
  }

  double solunarScore(SolunarPeriod period) => period.weight;

  String solunarDetail(SolunarPeriod period) {
    switch (period) {
      case SolunarPeriod.major:
        return 'Solunar major — peak feeding period';
      case SolunarPeriod.minor:
        return 'Solunar minor — a lesser feeding period';
      case SolunarPeriod.none:
        return 'Outside solunar periods';
    }
  }

  /// Score a single hour, returning the 0..100 value and the per-driver breakdown.
  HourScore scoreHour(HourSample s, {required bool tideMatters}) {
    final pressure = pressureScore(s.pressureTrend3h);
    final tide = tideScore(s.tideMovement, tideMatters: tideMatters);
    final solunar = solunarScore(s.solunar);
    final wind = windScore(s.windKph);

    final contributions = <DriverContribution>[
      DriverContribution(
        label: 'Pressure',
        detail: pressureDetail(s.pressureTrend3h),
        score01: pressure,
        weight: _wPressure,
      ),
      DriverContribution(
        label: 'Tide',
        detail: tideDetail(
          s.tideState,
          s.tideMovement,
          tideMatters: tideMatters,
        ),
        score01: tide,
        weight: _wTide,
      ),
      DriverContribution(
        label: 'Solunar',
        detail: solunarDetail(s.solunar),
        score01: solunar,
        weight: _wSolunar,
      ),
      DriverContribution(
        label: 'Wind',
        detail: windDetail(s.windKph),
        score01: wind,
        weight: _wWind,
      ),
    ];

    final total = contributions.fold<double>(0, (sum, c) => sum + c.points);
    return HourScore(sample: s, score: total, contributions: contributions);
  }

  /// Find the highest-scoring contiguous window of [length] hours.
  BiteWindow bestWindow(List<HourScore> hours, {int length = windowLength}) {
    if (hours.isEmpty) {
      return const BiteWindow(startHour: 0, endHour: 0, score: 0);
    }
    final n = hours.length;
    final win = math.min(length, n);
    var bestStart = 0;
    var bestAvg = double.negativeInfinity;
    for (var i = 0; i + win <= n; i++) {
      var sum = 0.0;
      for (var j = i; j < i + win; j++) {
        sum += hours[j].score;
      }
      final avg = sum / win;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestStart = i;
      }
    }
    final startHour = hours[bestStart].sample.hour;
    return BiteWindow(
      startHour: startHour,
      endHour: startHour + win,
      score: bestAvg,
    );
  }

  /// Find the best window that fits inside an available hour range. If the
  /// range cannot contain a full window, fall back to the all-day best window.
  BiteWindow bestWindowWithin(
    List<HourScore> hours, {
    required int startHour,
    required int endHour,
    int length = windowLength,
  }) {
    if (hours.isEmpty || endHour - startHour < length) {
      return bestWindow(hours, length: length);
    }
    final candidates = hours
        .where((h) => h.sample.hour >= startHour && h.sample.hour < endHour)
        .toList(growable: false);
    if (candidates.length < length) return bestWindow(hours, length: length);
    return bestWindow(candidates, length: length);
  }

  /// Score an entire day.
  DayScore scoreDay(DayForecast forecast, {required bool tideMatters}) {
    final hourScores = forecast.hours
        .map((h) => scoreHour(h, tideMatters: tideMatters))
        .toList(growable: false);
    final window = bestWindow(hourScores);
    return DayScore(
      forecast: forecast,
      hourScores: hourScores,
      bestWindow: window,
      dayScore: window.score,
    );
  }

  /// Score a week and return the days (caller can rank them).
  List<DayScore> scoreWeek(
    List<DayForecast> week, {
    required bool tideMatters,
  }) {
    return week
        .map((d) => scoreDay(d, tideMatters: tideMatters))
        .toList(growable: false);
  }
}
