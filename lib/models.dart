// Core domain models for FishSignal.
//
// FishSignal is a pressure-aware, tide-aware fishing bite-window forecast.
// Everything in this file is plain data — no UI, no I/O. The numbers that
// drive the bite score (pressure trend, tide movement, wind, solunar) are the
// honest, named inputs; see `score_engine.dart` for how they combine.

/// The kind of water an angler primarily fishes. Influences how heavily tide
/// movement matters in the bite score (saltwater leans on tide more).
enum WaterType {
  saltShore('Salt / shore', 'Beaches, estuaries, rock marks'),
  saltBoat('Salt / boat', 'Inshore and small-boat marks'),
  freshwater('Freshwater', 'Rivers, lakes and canals');

  const WaterType(this.label, this.blurb);

  final String label;
  final String blurb;

  /// How much tide movement should weigh for this water type (0..1).
  /// Freshwater has negligible tide, so it leans on pressure and solunar.
  bool get tideMatters => this != WaterType.freshwater;
}

/// A coarse, plain-language description of the tide at a given hour.
enum TideState {
  lowSlack('Low slack', 'Water barely moving'),
  flooding('Flooding', 'Tide pushing in'),
  midFlood('Mid-flood', 'Strong run of water'),
  highSlack('High slack', 'Water barely moving'),
  ebbing('Ebbing', 'Tide draining out'),
  midEbb('Mid-ebb', 'Strong run of water'),
  none('No tide', 'Inland water');

  const TideState(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// The strength of the solunar period at a given hour.
enum SolunarPeriod {
  major('Major', 1.0),
  minor('Minor', 0.6),
  none('Quiet', 0.2);

  const SolunarPeriod(this.label, this.weight);

  final String label;
  final double weight;
}

/// A single hour of honest, mocked forecast inputs for one spot.
///
/// These are the raw drivers. The score engine turns them into a 0..100 bite
/// score; nothing here is a pre-baked score.
class HourSample {
  const HourSample({
    required this.hour,
    required this.pressureHpa,
    required this.pressureTrend3h,
    required this.tideState,
    required this.tideMovement,
    required this.windKph,
    required this.solunar,
  });

  /// Hour of the day, 0..23.
  final int hour;

  /// Barometric pressure in hPa (millibars).
  final double pressureHpa;

  /// Change in pressure over the last 3 hours, in hPa.
  /// Negative = falling (anglers' favourite), positive = rising.
  final double pressureTrend3h;

  final TideState tideState;

  /// How fast the water is moving, 0 (slack) .. 1 (peak run).
  final double tideMovement;

  final double windKph;

  final SolunarPeriod solunar;

  String get clockLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 ? 'AM' : 'PM';
    return '$h $suffix';
  }
}

/// One day of forecast for one spot: 24 hourly samples plus the day's date.
class DayForecast {
  const DayForecast({required this.date, required this.hours});

  final DateTime date;
  final List<HourSample> hours;

  String get weekdayLabel {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(date.weekday - 1) % 7];
  }

  String get dateLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// A saved fishing spot. `isHomeMark` flags the angler's default place.
class Spot {
  Spot({
    required this.id,
    required this.name,
    required this.area,
    required this.waterType,
    this.isHomeMark = false,
    this.alertEnabled = false,
  });

  final String id;
  String name;
  String area;
  WaterType waterType;
  bool isHomeMark;

  /// Facade only — the prototype never schedules a real notification.
  bool alertEnabled;
}
