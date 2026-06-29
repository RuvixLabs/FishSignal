import 'package:fishsignal/app_state.dart';
import 'package:fishsignal/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding profile saves an exact local window alert', () {
    final state = AppState();
    final homeId = state.spots.first.id;

    state.completeOnboarding(
      waterType: WaterType.saltShore,
      homeSpotId: homeId,
      tripRhythm: TripRhythm.afterWork,
      alertIntent: true,
    );

    final spot = state.activeSpot!;
    final today = state.todayFor(spot);

    expect(state.onboardingComplete, isTrue);
    expect(state.tripRhythm, TripRhythm.afterWork);
    expect(state.alertFor(spot.id, today), isNotNull);
    expect(state.savedAlerts.single.spotName, spot.name);
  });

  test('share card uses the scored window and spot target', () {
    final state = AppState();
    final spot = state.spots.first;
    final today = state.todayFor(spot);

    final card = state.shareCardFor(spot, today);

    expect(card, contains(spot.name));
    expect(card, contains(today.bestWindow.rangeLabel));
    expect(card, contains(spot.target));
    expect(card, contains('no catch guarantee'));
  });
}
