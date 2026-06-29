import 'package:fishsignal/models.dart';
import 'package:fishsignal/score_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ScoreEngine();

  test('falling pressure scores higher than rising pressure', () {
    expect(engine.pressureScore(-3), greaterThan(engine.pressureScore(2)));
  });

  test('strong tide movement beats slack water when tide matters', () {
    expect(
      engine.tideScore(0.85, tideMatters: true),
      greaterThan(engine.tideScore(0.05, tideMatters: true)),
    );
  });

  test('bestWindow picks the highest contiguous two-hour average', () {
    HourSample sample(int hour) => HourSample(
      hour: hour,
      pressureHpa: 1010,
      pressureTrend3h: 0,
      tideState: TideState.flooding,
      tideMovement: 0.5,
      windKph: 12,
      solunar: SolunarPeriod.none,
    );

    final hours = [
      HourScore(sample: sample(5), score: 20, contributions: const []),
      HourScore(sample: sample(6), score: 80, contributions: const []),
      HourScore(sample: sample(7), score: 90, contributions: const []),
      HourScore(sample: sample(8), score: 30, contributions: const []),
    ];

    final window = engine.bestWindow(hours);

    expect(window.startHour, 6);
    expect(window.endHour, 8);
    expect(window.rounded, 85);
  });

  test('bestWindowWithin respects the requested hour range', () {
    HourSample sample(int hour) => HourSample(
      hour: hour,
      pressureHpa: 1010,
      pressureTrend3h: 0,
      tideState: TideState.flooding,
      tideMovement: 0.5,
      windKph: 12,
      solunar: SolunarPeriod.none,
    );

    final hours = [
      HourScore(sample: sample(5), score: 95, contributions: const []),
      HourScore(sample: sample(6), score: 90, contributions: const []),
      HourScore(sample: sample(17), score: 65, contributions: const []),
      HourScore(sample: sample(18), score: 70, contributions: const []),
    ];

    final window = engine.bestWindowWithin(hours, startHour: 16, endHour: 22);

    expect(window.startHour, 17);
    expect(window.endHour, 19);
    expect(window.rounded, 68);
  });

  test('scoreHour returns named driver contributions', () {
    const sample = HourSample(
      hour: 6,
      pressureHpa: 1007,
      pressureTrend3h: -2.5,
      tideState: TideState.midFlood,
      tideMovement: 0.9,
      windKph: 14,
      solunar: SolunarPeriod.major,
    );

    final scored = engine.scoreHour(sample, tideMatters: true);

    expect(scored.score, greaterThan(70));
    expect(scored.contributions.map((c) => c.label), [
      'Pressure',
      'Tide',
      'Solunar',
      'Wind',
    ]);
  });
}
