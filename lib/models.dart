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

/// When the angler can realistically fish. This does not fake the score; it
/// lets the app compare the all-day best window with the user's real free time.
enum TripRhythm {
  dawn('Dawn patrol', 'Before work / first light', 4, 10),
  tideFlexible('Tide-led', 'I can follow the best water', 0, 24),
  afterWork('After work', 'Late afternoon into dusk', 16, 22);

  const TripRhythm(this.label, this.blurb, this.startHour, this.endHour);

  final String label;
  final String blurb;
  final int startHour;
  final int endHour;

  bool get allDay => startHour == 0 && endHour == 24;

  String get windowLabel =>
      allDay ? 'Any good tide' : '${_fmt(startHour)}-${_fmt(endHour)}';

  static String _fmt(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 || hour == 24 ? 'AM' : 'PM';
    return '$h $suffix';
  }
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
    required this.target,
    required this.accessNote,
    this.isHomeMark = false,
    this.alertEnabled = false,
  });

  final String id;
  String name;
  String area;
  WaterType waterType;
  String target;
  String accessNote;
  bool isHomeMark;

  /// Facade only — the prototype never schedules a real notification.
  bool alertEnabled;
}

/// A concrete local save of one planned bite window. Still a prototype artifact:
/// no native notification is scheduled, but the app now remembers the exact
/// window the user asked to be nudged for.
class SavedWindowAlert {
  const SavedWindowAlert({
    required this.spotId,
    required this.spotName,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.score,
    this.leadMinutes = 60,
  });

  final String spotId;
  final String spotName;
  final DateTime date;
  final int startHour;
  final int endHour;
  final int score;
  final int leadMinutes;

  String get id => '$spotId-${date.year}-${date.month}-${date.day}-$startHour';

  String get rangeLabel => '${_fmt(startHour)} - ${_fmt(endHour)}';

  String get leadLabel =>
      leadMinutes == 60 ? '1 hour before' : '$leadMinutes min before';

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

  static String _fmt(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 || hour == 24 ? 'AM' : 'PM';
    final hh = hour == 24 ? 12 : h;
    return '$hh ${hour == 24 ? 'AM' : suffix}';
  }
}
