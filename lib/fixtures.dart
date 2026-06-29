// Mocked forecast fixtures for FishSignal.
//
// EVERYTHING here is fabricated, deterministic sample data. There is no network,
// no WeatherKit, no tide API. The app labels this clearly in-app. Data is
// seeded from the spot id + day index so a given spot always looks the same
// across launches, and different spots genuinely differ.

import 'dart:math' as math;

import 'models.dart';

/// Sample spots the prototype ships with. Includes a home mark so the spots
/// screen has switching, delete and "home mark" behaviour to demonstrate.
List<Spot> seedSpots() => [
  Spot(
    id: 'spot-chesil',
    name: 'Chesil Cove',
    area: 'Portland, Dorset',
    waterType: WaterType.saltShore,
    target: 'Bass, wrasse and mackerel',
    accessNote: 'Rock mark with a tide-led bite',
    isHomeMark: true,
    alertEnabled: true,
  ),
  Spot(
    id: 'spot-poole',
    name: 'Poole Harbour run',
    area: 'Poole, Dorset',
    waterType: WaterType.saltBoat,
    target: 'Flounder and school bass',
    accessNote: 'Sheltered harbour water',
  ),
  Spot(
    id: 'spot-kennet',
    name: 'River Kennet — willows',
    area: 'Newbury, Berkshire',
    waterType: WaterType.freshwater,
    target: 'Chub, perch and roach',
    accessNote: 'Inland swim where pressure matters more than tide',
  ),
];

/// Deterministic forecast generator. Given a spot and an anchor date, produces
/// [days] of 24-hour samples. The shape is realistic-ish but invented.
class FixtureForecaster {
  const FixtureForecaster();

  int _seedFor(String spotId, int dayIndex) {
    var h = 7;
    for (final code in spotId.codeUnits) {
      h = (h * 31 + code) & 0x7fffffff;
    }
    return (h + dayIndex * 101) & 0x7fffffff;
  }

  List<DayForecast> week(Spot spot, {DateTime? anchor, int days = 7}) {
    final base = anchor ?? DateTime(2026, 6, 22);
    return List<DayForecast>.generate(days, (d) {
      final rng = math.Random(_seedFor(spot.id, d));
      final date = DateTime(
        base.year,
        base.month,
        base.day,
      ).add(Duration(days: d));
      return DayForecast(date: date, hours: _hours(spot, rng, d));
    });
  }

  List<HourSample> _hours(Spot spot, math.Random rng, int dayIndex) {
    final tidal = spot.waterType.tideMatters;

    // A daily pressure baseline that drifts day to day, plus a trend direction.
    final basePressure = 1004.0 + rng.nextDouble() * 22.0; // 1004..1026 hPa
    // Trend sign: some days falling (good), some rising.
    final dayTrend =
        (rng.nextDouble() - 0.55) * 2.4; // mostly mild, slight bias to falling

    // Two solunar majors and two minors at pseudo-random, spot-stable hours.
    final majorA = rng.nextInt(6) + 4; // morning major 4..9
    final majorB = rng.nextInt(6) + 16; // evening major 16..21
    final minorA = (majorA + 6) % 24;
    final minorB = (majorB + 6) % 24;

    // Tide: ~12.4h cycle. Offset shifts each day so highs march forward.
    final tideOffset = (dayIndex * 0.8 + rng.nextDouble()) % 12.4;

    final windBase = 4.0 + rng.nextDouble() * 26.0; // 4..30 kph baseline

    return List<HourSample>.generate(24, (hour) {
      // Pressure trend over the hour wiggles around the day trend.
      final trend = dayTrend + (rng.nextDouble() - 0.5) * 1.0;
      final pressure = basePressure + dayTrend * (hour / 24.0) * 3;

      // Solunar period for this hour.
      SolunarPeriod solunar;
      if (hour == majorA || hour == majorB) {
        solunar = SolunarPeriod.major;
      } else if (hour == ((majorA + 1) % 24) ||
          hour == ((majorB + 1) % 24) ||
          hour == minorA ||
          hour == minorB) {
        solunar = SolunarPeriod.minor;
      } else {
        solunar = SolunarPeriod.none;
      }

      // Tide movement from a sine of the semi-diurnal cycle.
      final phase = ((hour - tideOffset) / 12.4) * 2 * math.pi;
      final heightSin = math.sin(phase); // -1 high/low extremes -> slack
      final movement = tidal ? (math.cos(phase)).abs() : 0.0; // peak mid-tide
      final TideState tideState;
      if (!tidal) {
        tideState = TideState.none;
      } else if (movement < 0.18) {
        tideState = heightSin > 0 ? TideState.highSlack : TideState.lowSlack;
      } else {
        // cos>0 means rising toward high in this construction.
        final rising = math.cos(phase) > 0;
        if (movement > 0.7) {
          tideState = rising ? TideState.midFlood : TideState.midEbb;
        } else {
          tideState = rising ? TideState.flooding : TideState.ebbing;
        }
      }

      // Wind eases overnight, freshens midday.
      final diurnal = math.sin((hour - 6) / 24 * 2 * math.pi) * 6;
      final wind = (windBase + diurnal + (rng.nextDouble() - 0.5) * 4)
          .clamp(0.0, 55.0)
          .toDouble();

      return HourSample(
        hour: hour,
        pressureHpa: double.parse(pressure.toStringAsFixed(1)),
        pressureTrend3h: double.parse(trend.toStringAsFixed(2)),
        tideState: tideState,
        tideMovement: double.parse(movement.toStringAsFixed(3)),
        windKph: double.parse(wind.toStringAsFixed(1)),
        solunar: solunar,
      );
    });
  }
}
